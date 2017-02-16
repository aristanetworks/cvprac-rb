# encoding: utf-8
# BSD 3-Clause License
#
# Copyright (c) 2017, Arista Networks EOS+
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

require 'json'
require 'pp'
require 'require_all'
require_all 'lib/cvprac/api/*.rb'

# Abstract methods for interacting with Arista CloudVision
#
# CvpApi provides high-level, convenience methods which utilize CvpClient for
# handling communications with CVP.
#
# @example Basic usage
#   require 'cvprac'
#   cvp = CvpClient.new
#   cvp.connect(['cvp1', 'cvp2', 'cvp3'], 'cvpadmin', 'arista123')
#   api = CvpApi.new(cvp)
#   result = api.get_cvp_info
#   print result
#   {"version"=>"2016.1.1"}
#
# @author Arista EOS+ Consulting Services <eosplus-dev@arista.com>
class CvpApi
  include Cvprac::Api::Info
  include Cvprac::Api::Configlet
  include Cvprac::Api::Task

  # Initialize a new CvpClient object
  #
  # @param [CvpClient] clnt CvpClient object
  # @param opts [Hash] optional parameters
  # @option opts [Fixnum] :request_timeout (30) Max seconds for a request
  def initialize(clnt, **opts)
    opts = { request_timeout: 30 }.merge(opts)
    @clnt = clnt
    @request_timeout = opts[:request_timeout]
  end

  # @see #CvpClient.log
  def log(severity = Logger::INFO, msg = nil)
    msg = yield if block_given?
    @clnt.log(severity, msg)
  end
end
