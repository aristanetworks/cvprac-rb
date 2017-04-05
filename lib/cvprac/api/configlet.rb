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
    # CVP Configlet api methods
    # rubocop:disable Metrics/ModuleLength
    module Configlet
      # @!group Configlet Method Summary

      # Add configlet
      #
      # @param [String] name The name of the desired configlet
      # @param [String] config Multiline string of EOS configuration
      #
      # @return [String, nil] The key for the new configlet. nil on failure
      #
      # @raise CvpApiError on failure.  Common: errorCode: 132518: Data already
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
      # @raise CvpApiError on failure.  Common when name or key is invalid:
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

      # Get devices associated with a configlet name
      #
      # @param [String] name The name of the desired configlet
      # @param opts [Hash] Optional arguments
      # @option opts [String] :queryparam Search string
      # @option opts [Fixnum] :start_index (0) Start index for pagination
      # @option opts [Fixnum] :end_index (0) End index for pagination
      #
      # @return [Hash] configlet definition
      #
      # @example
      #    configlet = api.get_configlet_by_name('api_test_3')
      #
      def get_devices_by_configlet_name(name, **opts)
        opts = { queryparam: nil,
                 start_index: 0,
                 end_index: 0 }.merge(opts)
        log(Logger::DEBUG) { "get_configlet_by_name: #{name}" }
        @clnt.get('/configlet/getAppliedDevices.do',
                  data: { configletName: name,
                          queryparam: opts[:queryparam],
                          startIndex: opts[:start_index],
                          endIndex: opts[:end_index] })
      end

      # Apply configlets to a device
      #
      # @param [String] app_name The name to use in the info field
      # @param [Hash] device Device definition from #get_device_by_id()
      # @param [Hash] new_configlets List of configlet name & key pairs
      #
      # @return [Hash] Hash including status and a list of task IDs created,
      #   if any
      #
      # @example
      #    result = api.apply_configlets_to_device('test',
      #                                            {...},
      #                                            [{'name' => 'new_configlet',
      #                                              'key' => '...'}])
      #    => {"data"=>{"taskIds"=>["8"], "status"=>"success"}}
      #
      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def apply_configlets_to_device(app_name, device, new_configlets)
        log(Logger::DEBUG) { "apply_configlets_to_device: #{app_name}" }

        # get the list of existing configlets
        configlets = get_configlets_by_device_id(device['systemMacAddress'])

        # Get a list of the configlet names and keys
        cnames = []
        ckeys = []
        configlets.each do |configlet|
          cnames << configlet['name']
          ckeys << configlet['key']
        end

        new_configlets.each do |configlet|
          cnames << configlet['name']
          ckeys << configlet['key']
        end

        info = "#{app_name}: Configlet Assign: to Device #{device['fqdn']}"
        info_preview = "<b>Configlet Assign:</b> to Device #{device['fqdn']}"
        data = { data: [{ id: 1,
                          info: info,
                          infoPreview: info_preview,
                          note: '',
                          action: 'associate',
                          nodeType: 'configlet',
                          nodeId: '',
                          configletList: ckeys,
                          configletNamesList: cnames,
                          ignoreConfigletNamesList: [],
                          ignoreConfigletList: [],
                          configletBuilderList: [],
                          configletBuilderNamesList: [],
                          ignoreConfigletBuilderList: [],
                          ignoreConfigletBuilderNamesList: [],
                          toId: device['systemMacAddress'],
                          toIdType: 'netelement',
                          fromId: '',
                          nodeName: '',
                          fromName: '',
                          toName: device['fqdn'],
                          nodeIpAddress: device['ipAddress'],
                          nodeTargetIpAddress: device['ipAddress'],
                          childTasks: [],
                          parentTask: '' }] }
        log(Logger::DEBUG) do
          "#{__method__}: saveTopology data #{data['data']}"
        end
        add_temp_action(data)
        save_topology_v2([])
      end

      # Remove configlets from a device
      #
      # @param [String] app_name The name to use in the info field
      # @param [Hash] device Device definition from #get_device_by_id()
      # @param [Hash] configlets List of configlet name & key pairs to remove
      #
      # @return [Hash] Hash including status and a list of task IDs created,
      #   if any
      #
      # @example
      #    result = api.remove_configlets_from_device('test',
      #                                               {...},
      #                                               [{'name' => 'configlet',
      #                                                 'key' => '...'}])
      #    => {"data"=>{"taskIds"=>["8"], "status"=>"success"}}
      #
      def remove_configlets_from_device(app_name, device, configlets)
        log(Logger::DEBUG) { "#{__method__}: #{app_name}" }

        # get the list of existing configlets
        curr_cfglts = get_configlets_by_device_id(device['systemMacAddress'])

        # Get a list of the configlet names and keys
        cnames = []
        ckeys = []
        curr_cfglts.each do |configlet|
          cnames << configlet['name']
          ckeys << configlet['key']
        end

        configlets.each do |configlet|
          cnames.delete(configlet['name'])
          ckeys.delete(configlet['key'])
        end

        info = "#{app_name}: Configlet Remove from Device #{device['fqdn']}"
        info_preview = "<b>Configlet Remove:</b> from Device #{device['fqdn']}"
        data = { data: [{ id: 1,
                          info: info,
                          infoPreview: info_preview,
                          note: '',
                          action: 'associate',
                          nodeType: 'configlet',
                          nodeId: '',
                          configletList: ckeys,
                          configletNamesList: cnames,
                          ignoreConfigletNamesList: [],
                          ignoreConfigletList: [],
                          configletBuilderList: [],
                          configletBuilderNamesList: [],
                          ignoreConfigletBuilderList: [],
                          ignoreConfigletBuilderNamesList: [],
                          toId: device['systemMacAddress'],
                          toIdType: 'netelement',
                          fromId: '',
                          nodeName: '',
                          fromName: '',
                          toName: device['fqdn'],
                          nodeIpAddress: device['ipAddress'],
                          nodeTargetIpAddress: device['ipAddress'],
                          childTasks: [],
                          parentTask: '' }] }
        log(Logger::DEBUG) do
          "#{__method__}: saveTopology data #{data['data']}"
        end
        add_temp_action(data)
        save_topology_v2([])
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
    end
  end
end
