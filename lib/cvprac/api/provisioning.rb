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
  # Cvprac::Api namespace
  module Api
    # CVP Info api methods
    module Provisioning
      # @!group Provisioning Method Summary

      # Get configlets by device ID
      #
      # @param [String] sys_mac The netElementId (System MAC) of the device
      # @param opts [Hash] Optional arguments
      # @option opts [String] :queryparam Search string
      # @option opts [Fixnum] :start_index (0) Start index for pagination
      # @option opts [Fixnum] :end_index (0) End index for pagination
      #
      # @return [Array] List of configlets applied to the device
      def get_configlets_by_device_id(sys_mac, **opts)
        opts = { queryparam: nil,
                 start_index: 0,
                 end_index: 0 }.merge(opts)
        log(Logger::DEBUG) { "get_configlets_by_device_id: #{sys_mac}" }
        res = @clnt.get('/provisioning/getConfigletsByNetElementId.do',
                        data: { netElementId: sys_mac,
                                queryParam: opts['queryparam'],
                                startIndex: opts['start_index'],
                                endIndex: opts['end_index'] })
        res['configletList']
      end
    end
  end
end
