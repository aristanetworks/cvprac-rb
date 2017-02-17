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
# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength, Metrics/AbcSize

require 'cgi'
require 'http-cookie'
require 'json'
require 'logger'
require 'net/http'
require 'pp'
require 'syslog/logger'

# Provide simplified RESTful methods to access Arista CloudVision Portal
#
# Establish and maintain connections with Arista CloudVision Portal servers,
# providing basic RESTful methods which handle session, cookie, and reconnects
# behind the scenes.
#
# @example Basic usage
#   require 'cvprac'
#   cvp = CvpClient.new
#   cvp.connect(['cvp1', 'cvp2', 'cvp3'], 'cvpadmin', 'arista123')
#   result = cvp.get('/user/getUsers.do',
#                    data: {queryparam: nil,
#                           startIndex: 0,
#                           endIndex: 0})
#   pp(result)
#   {"total"=>1,
#    "users"=>
#     [{"userId"=>"cvpadmin",
#       "firstName"=>nil,
#       "email"=>"nobody@example.com",
#       "lastAccessed"=>1483726955950,
#       "userStatus"=>"Enabled",
#       "currentStatus"=>"Online",
#       "contactNumber"=>nil,
#       "factoryId"=>1,
#       "lastName"=>nil,
#       "password"=>nil,
#       "id"=>28}],
#    "roles"=>{"cvpadmin"=>["network-admin"]}}
#
#   cvp.post('/test/endpoint.do', body: '{"some":"data"}')
#
# @author Arista EOS+ Consulting Services <eosplus-dev@arista.com>
class CvpClient
  METHOD_LIST = {
    get: Net::HTTP::Get,
    post: Net::HTTP::Post,
    put: Net::HTTP::Put,
    head: Net::HTTP::Head,
    delete: Net::HTTP::Delete
  }.freeze
  private_constant :METHOD_LIST

  # Maximum number of times to retry a get or post to the same
  # CVP node.
  NUM_RETRY_REQUESTS = 3

  # @!attribute [rw] agent
  #   Agent is the first part of the complete User-Agent
  #   @example User-Agent
  #     "User-agent"=>"cvp_app (x86_64-darwin14) cvprac-rb/0.1.0"
  #   @return [String] Application name included in HTTP User-Agent passed to
  #     CloudVision Portal. (Default: $PROGRAM_NAME) The full User-Agent string
  #     includes the application name, system-OS, and cvprac version
  #     information.
  # @!attribute [rw] connect_timeout
  #   @return [Fixnum] Max number of seconds before failing an HTTP connect
  # @!attribute [rw] headers
  #   @return [Hash] HTTP request headers
  # @!attribute [rw] port
  #   @return [Fixnum] TCP port used for connections
  # @!attribute [rw] protocol
  #   @return [String] 'http' or 'https'
  # @!attribute [rw] ssl_verify_mode
  #   OpenSSL::SSL::VERIFY_NONE or OpenSSL::SSL::VERIFY_PEER
  #   @see http://ruby-doc.org/stdlib-2.0.0/libdoc/openssl/rdoc/OpenSSL.html#module-OpenSSL-label-Peer+Verification
  # @!attribute [rw] logger.level
  #   logger severity level: Logger::DEBUG < Logger::INFO < Logger::WARN <
  #   Logger::ERROR < Logger::FATAL.  This allows the user to increase or
  #   decrease the logging level of the STDOUT log as needed throughout their
  #   application.
  # @!attribute [rw] api
  #   An instance of CvpApi
  attr_accessor :agent, :connect_timeout, :headers,
                :port, :protocol, :ssl_verify_mode, :file_log_level, :api

  # @!attribute [r] cookies
  #   @return [HTTP::CookieJar] HTTP cookies sent with each authenticated
  #   request
  # @!attribute [r] headers
  #   @return [Hash] HTTP headers sent with each request
  # @!attribute [r] nodes
  #   @return [Array<String>] List of configured CloudVision Portal nodes
  attr_reader :cookies, :headers, :nodes

  def file_log_level=(value)
    @file_log_level = value
    # Update existing handles if they exist
    @logstdout.level = @file_log_level if @logstdout.level
    @logfile.level = @file_log_level if @logfile.level
  end

  # Initialize a new CvpClient object
  #
  # @param opts [Hash] Optional arguments
  # @option opts [String] :logger ('cvprac') Logging name for this service
  # @option opts [Bool] :syslog (false) Log to the syslog service?
  # @option opts [String] :filename (nil) A local logfile to use, if provided
  # @option opts [Logger::level] :file_log_level (Logger::INFO) The default
  #   logging level which will be recorded in the logs.  See the Logging
  #   rubygem for additional severity levels
  def initialize(**opts)
    opts = { logger: 'cvprac',
             syslog: false,
             filename: nil,
             file_log_level: Logger::INFO }.merge(opts)
    @agent = File.basename($PROGRAM_NAME)
    @agent_full = "#{@agent} (#{RUBY_PLATFORM}) "\
                  "cvprac-rb/#{Cvprac::VERSION}"
    @authdata = nil
    @connect_timeout = nil
    @cookies = HTTP::CookieJar.new
    @error_msg = nil
    @file_log_level = opts[:file_log_level]
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

    if opts[:filename] == 'STDOUT'
      @logstdout = Logger.new(STDOUT)
      @logstdout.level = @file_log_level
    else
      unless opts[:filename].nil?
        @logfile = Logger.new(opts[:filename])
        @logfile.level = @file_log_level
      end
    end
    @syslog = Syslog::Logger.new(opts[:filename]) if opts[:syslog]

    # Instantiate the CvpApi class
    @api = CvpApi.new(self)

    log(Logger::INFO, 'CvpClient initialized')
  end

  # Log message to all configured loggers
  #
  # @overload log(severity: Logger::INFO, msg: nil)
  #   @param severity [Logger] Severity to log to:
  #                          DEBUG < INFO < WARN < ERROR < FATAL
  #   @param msg [String] Message to log
  #
  # @overload log(severity: Logger::INFO)
  #   @param severity [Logger] Severity to log to:
  #                            DEBUG < INFO < WARN < ERROR < FATAL
  #   @yield [msg] Messages can be passed as a block to delay evaluation
  def log(severity = Logger::INFO, msg = nil)
    msg = yield if block_given?
    @logstdout.add(severity, msg) if defined? @logstdout
    @logfile.add(severity, msg) if defined? @logfile
    @syslog.add(severity, msg) if defined? @syslog
  end

  # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

  # Connect to one or more CVP nodes.
  #
  # @param nodes [Array] Hostnames or IPs of the CVP node or nodes
  # @param username [String] CVP username
  # @param password [String] CVP password
  #
  # @param opts [Hash] Optional arguments
  # @option opts [Fixnum] :connect_timeout (10) Seconds to wait before failing
  #   a connect. Default: 10
  # @option opts [String] :protocol ('https') 'http' or 'https' to use when
  #   connecting to the CVP. Default: https
  # @option opts [Fixnum] :port (nil) TCP port to which we should connect is
  #   not standard http/https port.
  # @option opts [Bool] :verify_ssl (false) Verify CVP SSL certificate?
  #   Requires that a valid (non-self-signed) certificate be installed on the
  #   CloudVision Portal node(s).
  def connect(nodes, username, password, **opts)
    opts = { connect_timeout: 10,
             protocol: 'https',
             port: nil,
             verify_ssl: false }.merge(opts)
    connect_timeout = opts[:connect_timeout]
    protocol = opts[:protocol]
    port = opts[:port]

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

    @ssl_verify_mode = if opts[:verify_ssl]
                         OpenSSL::SSL::VERIFY_PEER
                       else
                         OpenSSL::SSL::VERIFY_NONE
                       end

    create_session(nil)
    raise CvpLoginError, @error_msg unless @session
  end
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

  # @!group RESTful methods

  # Send an HTTP GET request with session data and return the response.
  #
  # @param endpoint [String] URL endpoint starting after `https://host:port/web`
  #
  # @param [Hash] opts Optional parameters
  # @option opts [Hash] :data (nil) query parameters
  #
  # @return [JSON] parsed response body
  def get(endpoint, **opts)
    data = opts.key?(:data) ? opts[:data] : nil
    make_request(:get, endpoint, data: data)
  end

  # Send an HTTP POST request with session data and return the response.
  #
  # @param endpoint [String] URL endpoint starting after `https://host:port/web`
  #
  # @param [Hash] opts Optional parameters
  # @option opts [JSON] :body (nil) JSON body to post
  # @option opts [Hash] :data (nil) query parameters
  # @return [Net::HTTP Response]
  def post(endpoint, **opts)
    data = opts.key?(:data) ? opts[:data] : nil
    body = opts.key?(:body) ? opts[:body] : nil
    make_request(:post, endpoint, data: data, body: body)
  end

  # @!endgroup RESTful methods

  private

  # Send an HTTP request with session data and return the response.
  #
  # @param method [Symbol] Reuqest method: :get, :post, :head, etc.
  # @param endpoint [String] URI path to the endpoint after /web/
  #
  # @param opts [Hash] Optional arguments
  # @option opts [JSON] :body JSON body to post
  # @option opts [Hash] :data query parameters
  # @option opts [Fixnum] :timeout (30) Seconds to timeout request.
  #
  # @return [JSON] parsed response body
  # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  def make_request(method, endpoint, **opts)
    log(Logger::DEBUG) do
      "entering make_request #{method} "\
                         "endpoint: #{endpoint}"
    end
    raise 'No valid session to a CVP node. Use #connect()' unless @session
    url = @url_prefix + endpoint

    opts = { data: nil, body: nil, timeout: 30 }.merge(opts)

    uri = URI(url)
    uri.query = URI.encode_www_form(opts[:data]) if opts[:data]
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = opts[:timeout]
    if @protocol == 'https'
      http.use_ssl = true
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
        request.body = opts[:body] if opts[:body]
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
    (0...node_count).each do
      host = @node_pool.next
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

  # Check the response from Net::HTTP
  #   If the response is not good data, generate a useful log message, then
  #   raise an appropriate exception.
  #
  # @param response [Net::HTTP response object]
  # @param prefix [String] Optional text to prepend to error messages
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
      err_msg = "errorCode: #{body['errorCode']}: #{body['errorMessage']}"
      log(Logger::ERROR) { err_msg }
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
