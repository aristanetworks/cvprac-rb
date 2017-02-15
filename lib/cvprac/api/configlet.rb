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

# @author Arista EOS+ Consulting Services <eosplus-dev@arista.com>
module Cvprac
  # CVP Configlet api methods
  module Api
    # CVP Configlet api methods
    module Configlet
      # @!group Configlet Method Summary

      # Add configlet
      #
      # @param [String] name The name of the desired configlet
      # @param [String] config Multiline string of EOS configuration
      #
      # @return [String, nil] The key for the new configlet. nil on failure
      #
      # @raises CvpApiError on failure.  Common: errorCode: 132518: Data already
      #   exists in Database.
      #
      # @example
      #    result = api.add_configlet('api_test_3',
      #                               "interface Ethernet1\n   shutdown")
      def add_configlet(name, config)
        log(Logger::DEBUG) do
          "add_configlet: #{name} Config: #{config.inspect}"
        end
        resp = @clnt.post('/configlet/addConfiglet.do',
                          body: { name: name, config: config.to_s }.to_json)
        # data = @clnt.get('/configlet/getConfigletByName.do',
        #                  data: { name: name })
        # print "Result: #{data.inspect}"
        # data['data']
        # print "Result: #{resp.inspect}"
        log(Logger::DEBUG) do
          "add_configlet: #{name} Response: #{resp.inspect}"
        end
        resp['data']
      end

      # Update configlet
      #
      # @param [String] name The name of the desired configlet
      # @param [String] key The configlet key
      # @param [Hash] config The configlet definition
      #
      # @return [String] The key for the new configlet
      #
      # @example
      #    result = api.update_configlet('api_test_3', configlet_new['key'],
      #                                  "interface Ethernet1\n   shutdown")
      def update_configlet(name, key, config)
        log(Logger::DEBUG) do
          "update_configlet: #{name} Key: #{key} Config: #{config.inspect}"
        end
        data = @clnt.post('/configlet/updateConfiglet.do',
                          body: { name: name, key: key,
                                  config: config }.to_json)
        data['data']
      end

      # Delete configlet
      #
      # @param [String] name The name of the desired configlet
      # @param [String] key The configlet key
      #
      # @return [String] The request result
      #
      # @raises CvpApiError on failure.  Common when name or key is invalid:
      #   errorCode: 132718: Invalid input parameters.
      def delete_configlet(name, key)
        log(Logger::DEBUG) { "delete_configlet: #{name} Key: #{key}" }
        resp = @clnt.post('/configlet/deleteConfiglet.do',
                          body: [{ name: name, key: key }].to_json)
        resp['data']
      end

      # Get all configlet definitions
      #
      # @param [Fixnum] start_i (0) Start index of pagination
      # @param [Fixnum] end_i (0) End index for pagination. 0 will get all
      # @param [String] type ('Configlet') Possible types are All, Configlet,
      #   Builder, Draft, Builderwithoutdraft, Generated, IgnoreDraft
      #
      # @return [Hash] configlet definitions with keys: total and data (a list
      #   of definitions)
      #
      # @example
      #    configlet = api.get_configlets()
      def get_configlets(start_i = 0, end_i = 0, type = 'Configlet')
        log(Logger::DEBUG) do
          "get_configlets: start=#{start_i}, end=#{end_i}, type=#{type}"
        end
        @clnt.get('/configlet/getConfiglets.do', data: { startIndex: start_i,
                                                         endIndex: end_i,
                                                         type: type })
      end

      # Get configlet definition by configlet name
      #
      # @param [String] name The name of the desired configlet
      #
      # @return [Hash] configlet definition
      #
      # @example
      #    configlet = api.get_configlet_by_name('api_test_3')
      def get_configlet_by_name(name)
        log(Logger::DEBUG) { "get_configlet_by_name: #{name}" }
        @clnt.get('/configlet/getConfigletByName.do', data: { name: name })
      end
    end
  end
end
