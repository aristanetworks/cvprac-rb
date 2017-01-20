# encoding: utf-8
# BSD 3-Clause License
#
# Copyright (c) 2016, Arista Networks EOS+
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name Arista nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# @author Jere Julian <jere@arista.com>
#
# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/ParameterLists

require 'cgi'
require 'http-cookie'
require 'json'
require 'logger'
require 'net/http'
require 'pp'
require 'syslog/logger'

# Establishes and maintains connections with CVP node(s)
#
# @example
#   $ bundle exec pry
#   [1] pry(main)> require 'cvprac'
#   => true
#   [2] pry(main)> cvp = CvpClient.new
#   => #<CvpClient:0x007fb0aa36c970>
#   [3] pry(main)> cvp.connect(['cvp1', 'cvp2', 'cvp3'], \
#                             'cvpadmin', 'arista123')
#   => nil
#   [4] pry(main)> result = cvp.get('/user/getUsers.do', {queryparam: nil, \
#                                   startIndex: 0, endIndex: 0})
#   [5] pry(main)> require 'pp'
#   [6] pry(main)> pp(result)
#   => {"total"=>1,
#    "users"=>
#     [{"userId"=>"cvpadmin",
#       "firstName"=>nil,

#       "email"=>"jere@arista.com",
#       "lastAccessed"=>1483726955950,
#       "userStatus"=>"Enabled",
#       "currentStatus"=>"Online",
#       "contactNumber"=>nil,
#       "factoryId"=>1,
#       "lastName"=>nil,
#       "password"=>nil,
#       "id"=>28}],
#    "roles"=>{"cvpadmin"=>["network-admin"]}}
class CvpClient
  METHOD_LIST = {
    get: Net::HTTP::Get,
    post: Net::HTTP::Post,
    put: Net::HTTP::Put,
    head: Net::HTTP::Head,
    delete: Net::HTTP::Delete
  }.freeze

  # Maximum number of times to retry a get or post to the same
  # CVP node.
  NUM_RETRY_REQUESTS = 3

  attr_accessor :agent, :connect_timeout, :headers,
                :port, :protocol

  attr_reader :cookies, :headers, :nodes

  attr_accessor :ssl_verify_mode

  # Initialize a new CvpClient object
  #
  # @param syslog [Bool] log to syslog (Default: false)
  # @param filename [String] Filename to write logs or :STDOUT
  def initialize(_logger = 'cvprac', syslog = false, filename = nil)
    @agent = File.basename($PROGRAM_NAME)
    @agent_full = "#{@agent} (#{RUBY_PLATFORM}) "\
                  "cvprac-rb/#{Cvprac::VERSION}"
    @authdata = nil
    @connect_timeout = nil
    @cookies = HTTP::CookieJar.new
    @error_msg = nil
    @headers = { 'Accept' => 'application/json',
                 'Content-Type' => 'application/json',
                 'User-agent' => @agent_full }
    @node_count = nil
    @node_pool = nil
    @nodes = nil
    @port = nil
    @protocol = nil
    @session = nil
    # OpenSSL::SSL::VERIFY_NONE or OpenSSL::SSL::VERIFY_PEER
    @ssl_verify_mode = OpenSSL::SSL::VERIFY_NONE
    @url_prefix = nil

    if filename == 'STDOUT'
      @logstdout = Logger.new(STDOUT)
      # @logstdout.level = Logger::INFO
      @logstdout.level = Logger::DEBUG
    else
      @logfile = Logger.new(filename) unless filename.nil?
    end
    @syslog = Syslog::Logger.new(filename) if syslog

    log(Logger::INFO, 'CvpClient initialized')
  end

  # Log message to all configured loggers
  #
  # @param severity [Logger] Severity to log to:
  #                          DEBUG < INFO < WARN < ERROR < FATAL
  # @param msg [String] Message to log
  # @param &block [block] Messages can be passed as a block to delay evaluation
  def log(severity = Logger::INFO, msg = nil)
    msg = yield if block_given?
    @logstdout.add(severity, msg) if defined? @logstdout
    @logfile.add(severity, msg) if defined? @logfile
    @syslog.add(severity, msg) if defined? @syslog
  end

  # Connect to one or more CVP nodes.
  #
  # @param nodes [Array] Hostnames or IPs of the CVP node or nodes
  # @param username [String] CVP username
  # @param password [String] CVP password
  # @param connect_timeout [Int] Seconds to wait before failing a connect
  # @param protocol [String] 'http' or 'https' to use when connecting to the CVP
  # @param port [Int] TCP port to which we should connect is not standard
  # http/https port.
  # rubocop:disable Metrics/PerceivedComplexity
  def connect(nodes, username, password, connect_timeout = 10,
              protocol = 'http', port = nil)
    @nodes = Array(nodes) # Ensure nodes is always an array
    @node_index = 0
    @node_count = nodes.length
    @node_last = @node_count - 1
    @node_pool = Enumerator.new do |y|
      loop do
        index = @node_index % @node_count
        if @node_index == @node_last
          @node_index = 0
        else
          @node_index += 1
        end
        y.yield @nodes[index]
      end
    end
    @authdata = { userId: username, password: password }
    @connect_timeout = connect_timeout
    @protocol = protocol

    if port.nil?
      if protocol == 'http'
        port = 80
      elsif protocol == 'https'
        port = 443
      else
        raise ArgumentError, "No default port for protocol: #{protocol}"
      end
    end
    @port = port

    create_session(nil)
    raise CvpLoginError, @error_msg unless @session
  end
  # rubocop:enable Metrics/PerceivedComplexity

  # Send an HTTP GET request with session data and return the response.
  #
  # @param endpoint [String] URL endpoint starting after `https://host:port/web`
  # @param :data [Hash] query parameters
  # @return [JSON] parsed response body
  def get(endpoint, **args)
    data = args.key?(:data) ? args[:data] : nil
    make_request(:get, endpoint, data: data)
  end

  # Send an HTTP POST request with session data and return the response.
  #
  # @param endpoint [String] URL endpoint starting after `https://host:port/web`
  # @param :body [JSON] JSON body to post
  # @param :data [Hash] query parameters
  # @return [Net::HTTP Response]
  def post(endpoint, **args)
    data = args.key?(:data) ? args[:data] : nil
    body = args.key?(:body) ? args[:body] : nil
    make_request(:post, endpoint, data: data, body: body)
  end

  private

  # Send an HTTP request with session data and return the response.
  #
  # @param method [Symbol] Reuqest method: :get, :post, :head, etc.
  # @param url [String] Full URL to the endpoint
  # @param :body [JSON] JSON body to post
  # @param :data [Hash] query parameters
  # @param :timeout [Int] Seconds to timeout request. Default: 30
  # @return [JSON] parsed response body
  # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  def make_request(method, endpoint, **args)
    log(Logger::DEBUG) do
      "entering make_request #{method} "\
                         "endpoint: #{endpoint}"
    end
    raise 'No valid session to a CVP node. Use #connect()' unless @session
    url = @url_prefix + endpoint

    data = args.key?(:data) ? args[:data] : nil
    body = args.key?(:body) ? args[:body] : nil
    timeout = args.key?(:timeout) ? args[:timeout] : 30

    uri = URI(url)
    uri.query = URI.encode_www_form(data) if data
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = timeout
    if @protocol == 'https'
      http.use_ssl = true
      # TODO: Parameterize and doc this!!!
      http.verify_mode = @ssl_verify_mode
    end

    error = nil
    retry_count = NUM_RETRY_REQUESTS
    node_count = @node_count
    while node_count > 0
      unless error.nil?
        log(Logger::DEBUG) { "make_request: error not nil: #{error}" }
        node_count -= 1
        raise error if node_count.zero?
        create_session

        raise error unless @session
        retry_count = NUM_RETRY_REQUESTS
        error = nil
      end

      begin
        log(Logger::DEBUG) { 'make_request: ' + uri.request_uri }
        request = METHOD_LIST[method].new(uri.request_uri, @headers)
        request.body = body if body
        response = http.request(request)
      rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
             Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
             Net::ProtocolError => error
        log(Logger::ERROR) { "Request failed: #{error}" }
        raise CvpRequestError, error
      rescue => error
        log(Logger::ERROR) { "UnknownError: #{error}" }
        raise error
      end
      log(Logger::DEBUG) { 'Request succeeded. Checking response...' }

      begin
        good_response?(response, "#{method} #{uri.request_uri}:")
      rescue CvpSessionLogOutError => error
        log(Logger::DEBUG) { "Session logged out: #{error}" }
        retry_count -= 1
        if retry_count > 0
          log(Logger::DEBUG) do
            'Session logged out... resetting and retrying '\
                               "#{error}"
          end
          reset_session
          error = nil if @session # rubocop:disable Metrics/BlockNesting
        else
          msg = 'Session logged out. Failed to re-login. '\
                "No more retries: #{error}"
          log(Logger::ERROR) { msg }
          raise CvpSessionLogOutError, msg
        end
        next
      end
      log(Logger::DEBUG) { 'make_request completed.' }
      break
    end

    response.body ? JSON.parse(response.body) : nil
  end
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

  # Login to CVP and get a session ID and user information.
  #  If the all_nodes parameter is True then try creating a session
  #  with each CVP node.  If False, then try creating a session with
  #  each node except the one currently connected to.
  #
  # @param all_nodes [Bool] Establish a session with each node or just one
  def create_session(all_nodes = nil)
    node_count = @node_count
    node_count -= 1 if all_nodes.nil? && node_count > 1

    @error_msg = '\n'
    (0...node_count).each do |id|
      # host = @node_pool.take(id)
      host = @nodes[id]
      @url_prefix = "#{@protocol}://#{host}:#{@port}/web"
      @http = Net::HTTP.new(host, @port)
      if @protocol == 'https'
        @http.use_ssl = true
        @http.verify_mode = @ssl_verify_mode
      end
      error = reset_session
      break if error.nil?
      @error_msg += "#{host}: #{error}\n"
    end
  end

  # Get a new request session and try logging into the current
  #   CVP node. If the login succeeded None will be returned and
  #   @session will be valid. If the login failed then an
  #   exception error will be returned and @session will
  #   be set to None.
  #
  # @return [String] nil on success or errors encountered
  def reset_session
    @session = nil
    error = nil

    begin
      login
    rescue CvpApiError, CvpRequestError, CvpSessionLogOutError => error
      log(Logger::ERROR) { error }
      # Invalidate the session due to error
      @session = nil
    end
    error
  end

  # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  def good_response?(response, prefix = '')
    log(Logger::DEBUG) { "response_code: #{response.code}" }
    log(Logger::DEBUG) { 'response_headers: ' + response.to_hash.to_s }
    log(Logger::DEBUG) { "response_body: #{response.body}" }
    if response.respond_to?('reason')
      log(Logger::DEBUG) { "response_reason: #{response.reason}" }
    end

    if response.code.to_i == 302
      msg = "#{prefix} Notice302: session logged out"
      log(Logger::DEBUG) { msg }
      raise CvpSessionLogOutError, msg
    elsif response.code.to_i != 200
      msg = "#{prefix}: Request Error"
      if response.code.to_i == 400
        title = response.body.match(%r{<h1>(.*?)</h1>})[1]
        msg = "#{prefix}: #{title}" if title
      end
      log(Logger::ERROR) { 'ErrorCode: ' + response.code + ' - ' + msg }
      msg += " Reason: #{response.reason}" if response.respond_to?('reason')
      raise CvpRequestError.new(response.code, msg)
    end

    log(Logger::DEBUG) { 'Got a response 200 with a body' }
    return unless response.body.to_s.include? 'errorCode'

    log(Logger::DEBUG) { 'Body has an errorCode' }
    body = JSON.parse(response.body)
    if body.key?('errorMessage')
      msg = "errorCode: #{body['errorCode']}: #{body['errorMessage']}"
      log(Logger::ERROR) { msg }
    else
      error_list = if body.key?('errors')
                     body['errors']
                   else
                     [body['errorMessage']]
                   end
      err_msg = error_list[0]
      (1...error_list.length).each do |idx|
        err_msg += "\n#{error_list[idx]}"
      end
    end

    msg = "#{prefix}: Request Error: #{err_msg}"
    log(Logger::ERROR) { msg }
    raise CvpApiError, msg
  end
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

  # Make a POST request to CVP login authentication.
  #   An error can be raised from the post method call or the
  #   good_response? method call.  Any errors raised would be a good
  #   reason not to use this host.
  #
  # @raise SomeError
  def login
    @headers.delete('APP_SESSION_ID')
    url = @url_prefix + '/login/authenticate.do'
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    if @protocol == 'https'
      http.use_ssl = true
      http.verify_mode = @ssl_verify_mode
    end

    request = Net::HTTP::Post.new(uri.path, @headers)
    request.body = @authdata.to_json
    log(Logger::DEBUG) { 'Sending login POST' }
    begin
      response = http.request(request)
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
           Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
           Net::ProtocolError => error
      log(Logger::ERROR) { 'Login failed: ' + error.to_s }
      raise CvpLoginError, error.to_s
    rescue => error
      log(Logger::ERROR) { 'Login failed UnkReason: ' + error.to_s }
      raise CvpLoginError, error.to_s
    end
    log(Logger::DEBUG) { 'Sent login POST' }

    good_response?(response, 'Authenticate:')
    log(Logger::DEBUG) { 'login checked response' }

    response.get_fields('Set-Cookie').each do |value|
      @cookies.parse(value, @url_prefix)
    end

    body = JSON.parse(response.body)
    @session = @headers['APP_SESSION_ID'] = body['sessionId']
    @headers['Cookie'] = HTTP::Cookie.cookie_value(@cookies.cookies)
    log(Logger::DEBUG) { 'login SUCCESS' }
  end
end
