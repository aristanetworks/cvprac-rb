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

RSpec.describe CvpApi do
  let(:cvp) { CvpClient.new }
  # Use for debugging
  # let(:cvp) { CvpClient.new('cvprac', true, 'STDOUT') }

  let(:accept_encoding) { 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3' }
  let(:content_type) { 'application/json;charset=UTF-8' }
  let(:dflt_headers) do
    { 'Accept' => 'application/json',
      'Accept-Encoding' => accept_encoding,
      'Content-Type' => 'application/json' }
  end
  let(:session_id) { 'session_1864826_14590036948865688' }
  let(:set_cookie) do
    ['JSESSIONID=1BB74E892E3B40408D8399330FC45674; Path=/web/; Secure; '\
     'HttpOnly',
     "session_id=#{session_id}; Path=/web/",
     'permissionList="[{"factoryId":1,"id":31,"name":"ztp","mode":"rw"},'\
     '{"factoryId":1,"id":31,"name":"aaa","mode":"rw"},'\
     '{"factoryId":1,"id":31,"name":"configlet","mode":"rw"},'\
     '{"factoryId":1,"id":31,"name":"label","mode":"rw"},'\
     '{"factoryId":1,"id":31,"name":"danz","mode":"rw"},'\
     '{"factoryId":1,"id":31,"name":"inventory","mode":"rw"},'\
     '{"factoryId":1,"id":31,"name":"cvpTheme","mode":"rw"},'\
     '{"factoryId":1,"id":31,"name":"task","mode":"rw"},'\
     '{"factoryId":1,"id":31,"name":"account","mode":"rw"},'\
     '{"factoryId":1,"id":31,"name":"image","mode":"rw"}]"; '\
     'Version=1; Path=/web/']
  end
  let(:good_cookie) do
    'JSESSIONID=1BB74E892E3B40408D8399330FC45674; '\
    'permissionList="[{factoryId:1,id:31,name:ztp,mode:rw},'\
    '{factoryId:1,id:31,name:aaa,mode:rw},'\
    '{factoryId:1,id:31,name:configlet,mode:rw},'\
    '{factoryId:1,id:31,name:label,mode:rw},'\
    '{factoryId:1,id:31,name:danz,mode:rw},'\
    '{factoryId:1,id:31,name:inventory,mode:rw},'\
    '{factoryId:1,id:31,name:cvpTheme,mode:rw},'\
    '{factoryId:1,id:31,name:task,mode:rw},'\
    '{factoryId:1,id:31,name:account,mode:rw},'\
    '{factoryId:1,id:31,name:image,mode:rw}]"; '\
    'session_id=session_1864826_14590036948865688'
  end
  let(:good_headers) do
    { 'Accept' => 'application/json',
      'Accept-Encoding' => accept_encoding,
      'Content-Type' => 'application/json',
      'Cookie' => good_cookie }
  end

  let(:login_body) { fixture('login_body') }

  before(:each) do
    stub_request(:post, 'https://cvp1.example.com/web/login/authenticate.do')
      .with(headers: dflt_headers)
      .to_return(body: login_body,
                 headers: { 'set-cookie' => set_cookie })
    cvp.connect(['cvp1.example.com'], 'cvpadmin', 'arista123')
  end

  let(:api) { CvpApi.new(cvp) }

  describe '#get_cvp_info' do
    let(:verb) { :get }
    let(:url) { 'https://cvp1.example.com/web/cvpInfo/getCvpInfo.do' }
    let(:resp_body) { %({ "version": "2016.1.1" }) }

    before do
      stub_request(verb, url)
        .with(headers: good_headers)
        .to_return(body: resp_body)
    end
    let(:response) { api.get_cvp_info }
    it 'returns a hash' do
      expect(response).to be_kind_of(Hash)
    end
    it 'returns the CVP version' do
      expect(response).to eq(JSON.parse(resp_body))
    end
  end

  describe '#add_configlet' do
    let(:verb) { :post }
    let(:url) { 'https://cvp1.example.com/web/configlet/addConfiglet.do' }
    let(:resp_body) { %({ "data": "configlet_1869686_21062192619368001" }) }

    before do
      stub_request(verb, url)
        .with(headers: good_headers)
        .to_return(body: resp_body)
    end
    let(:response) do
      api.add_configlet('api_test_3',
                        "interface Ethernet1\n   no shutdown")
    end
    it 'returns a string' do
      expect(response).to be_kind_of(String)
    end
    it 'returns the configlet key' do
      expect(response).to eq(JSON.parse(resp_body)['data'])
    end
  end

  describe '#delete_configlet' do
    let(:verb) { :post }
    let(:url) { 'https://cvp1.example.com/web/configlet/deleteConfiglet.do' }
    let(:resp_body) { %({"data":"success"}) }

    before do
      stub_request(verb, url)
        .with(headers: good_headers)
        .to_return(body: resp_body)
    end
    let(:response) do
      api.delete_configlet('api_test_3',
                           'configlet_1864955_16870562419823164')
    end
    it 'returns a string' do
      expect(response).to be_kind_of(String)
    end
    it 'returns success' do
      expect(response).to eq(JSON.parse(resp_body)['data'])
    end
    context 'with an invalid key' do
      let(:resp_body) do
        %({"errorCode":"132718","errorMessage":"Invalid input parameters."})
      end

      before do
        stub_request(verb, url)
          .with(headers: good_headers)
          .to_return(body: resp_body)
      end
      it 'raises CvpApiError' do
        expect do
          api.delete_configlet('api_test_3',
                               'configlet_1864975_16872535216220299')
        end.to raise_error(CvpApiError,
                           /errorCode: 132718: Invalid input parameters/)
      end
    end
  end

  describe '#update_configlet' do
    let(:verb) { :post }
    let(:url) { 'https://cvp1.example.com/web/configlet/updateConfiglet.do' }
    let(:resp_body) { %({ "data": "Configlet is successfully updated" }) }

    before do
      stub_request(verb, url)
        .with(headers: good_headers)
        .to_return(body: resp_body)
    end
    let(:response) do
      api.update_configlet('api_test_3', 'configlet_1864975_16872535216220299',
                           "interface Ethernet1\n   no shutdown")
    end
    it 'returns a string' do
      expect(response).to be_kind_of(String)
    end
    it 'returns a string message' do
      expect(response).to eq(JSON.parse(resp_body)['data'])
    end

    # NOTE: With an invalid name, the update succeeds in 2016.1.1
    context 'with an invalid key' do
      let(:resp_body) do
        %({"errorCode":"132532", "errorMessage":"Failure -  No data found."})
      end

      before do
        stub_request(verb, url)
          .with(headers: good_headers)
          .to_return(body: resp_body)
      end
      it 'raises CvpApiError' do
        expect do
          api.update_configlet('api_test_3',
                               'configlet_1864975_16872535216220299',
                               "interface Ethernet1\n   no shutdown")
        end.to raise_error(CvpApiError,
                           /errorCode: 132532: Failure -  No data found./)
      end
    end
  end

  describe '#get_configlet_by_name' do
    let(:verb) { :get }
    let(:params) { '?name=api_test_3' }
    let(:url) do
      'https://cvp1.example.com/web/configlet/getConfigletByName.do' + params
    end
    let(:resp_body) do
      '{"isDefault":"no","containerCount":0,"netElementCount":0,'\
      '"isAutoBuilder":"false","reconciled":false,'\
      '"dateTimeInLongFormat":1485917316929,"factoryId":1,"config":'\
      '"!username admin privilege 15 role network-admin secret 0'\
      ' admin\n!username cvpadmin privilege 15 role network-admin secret 0'\
      ' arista123\nusername admin privilege 15 role network-admin secret 5 '\
      '$1$7IJPvFto$.3IzcPDr5MJiBID8iCEFb1 \nusername cvpadmin privilege 15 '\
      'role network-admin secret 5 $1$e8zc.bhO$G1YLdeQGXLBS1J8T.oeJT/ \n! \n'\
      'management api http-commands\nno shutdown\n","user":"cvpadmin",'\
      '"note":null,"name":"api_test_0",'\
      '"key":"configlet_1864975_16872535216220299","id":3,"type":"Static" }'
    end

    before do
      stub_request(verb, url)
        .with(headers: good_headers)
        .to_return(body: resp_body)
    end
    let(:response) do
      api.get_configlet_by_name('api_test_3')
    end
    it 'returns a hash' do
      expect(response).to be_kind_of(Hash)
    end
    it 'returns the configlet definition' do
      expect(response).to eq(JSON.parse(resp_body))
    end

    context 'with a non-existent configlet name' do
      let(:resp_body) do
        %({"errorCode":"132801","errorMessage":"Entity does not exist"})
      end

      before do
        stub_request(verb, url)
          .with(headers: good_headers)
          .to_return(body: resp_body)
      end
      it 'raises CvpApiError' do
        expect do
          api.get_configlet_by_name('api_test_3')
        end.to raise_error(CvpApiError,
                           /errorCode: 132801: Entity does not exist/)
      end
    end
  end

  describe 'Adding & removing configlets to devices' do
    let(:verb) { :get }
    let(:params) { '?name=api_test_3' }
    let(:url) do
      'https://cvp1.example.com/web/configlet/getConfigletByName.do' + params
    end
    let(:resp_body) do
      '{"isDefault":"no","containerCount":0,"netElementCount":0,'\
      '"isAutoBuilder":"false","reconciled":false,'\
      '"dateTimeInLongFormat":1485917316929,"factoryId":1,"config":'\
      '"!username admin privilege 15 role network-admin secret 0'\
      ' admin\n!username cvpadmin privilege 15 role network-admin secret 0'\
      ' arista123\nusername admin privilege 15 role network-admin secret 5 '\
      '$1$7IJPvFto$.3IzcPDr5MJiBID8iCEFb1 \nusername cvpadmin privilege 15 '\
      'role network-admin secret 5 $1$e8zc.bhO$G1YLdeQGXLBS1J8T.oeJT/ \n! \n'\
      'management api http-commands\nno shutdown\n","user":"cvpadmin",'\
      '"note":null,"name":"api_test_0",'\
      '"key":"configlet_1864975_16872535216220299","id":3,"type":"Static" }'
    end
    let(:configlets_by_device) do
      [{ 'isDefault' => 'no',
         'containerCount' => 0,
         'netElementCount' => 0,
         'isAutoBuilder' => 'false',
         'reconciled' => false,
         'dateTimeInLongFormat' => 1_488_396_770_908,
         'factoryId' => 1,
         'config' => "interface ethernet4\n   description Puppet was rot here"\
         "\nend",
         'user' => 'cvpadmin',
         'note' => nil,
         'name' => 'api_test_1',
         'key' => 'configlet_1866269_19351988468666178',
         'id' => 3,
         'type' => 'Static' },
       { 'isDefault' => 'no',
         'containerCount' => 0,
         'netElementCount' => 0,
         'isAutoBuilder' => 'true',
         'reconciled' => false,
         'dateTimeInLongFormat' => 1_473_364_667_402,
         'factoryId' => 1,
         'config' => '',
         'user' => 'cvpadmin',
         'note' => nil,
         'name' => 'configlet_ipam_builder',
         'key' => 'configletBuilderMapper_19_22638914337350',
         'id' => 3,
         'type' => 'Builder' },
       { 'isDefault' => 'no',
         'containerCount' => 0,
         'netElementCount' => 0,
         'isAutoBuilder' => 'false',
         'reconciled' => false,
         'dateTimeInLongFormat' => 1_469_068_927_533,
         'factoryId' => 1,
         'config' =>
           "hostname veos-l-11\ninterface Management1\n"\
           "   ip address 192.0.2.200/24\nip routing\n"\
           "ip route vrf default 0.0.0.0/0 192.0.2.254\n"\
           "ip name-server vrf default 192.0.2.254\n"\
           "ip domain-name aristanetworks.com\n",
         'user' => 'cvpadmin',
         'note' => nil,
         'name' => 'configlet_ipam_builder_192.0.2.200_1',
         'key' => 'configlet_70_24148965410223',
         'id' => 3,
         'type' => 'Generated' },
       { 'isDefault' => 'no',
         'containerCount' => 0,
         'netElementCount' => 0,
         'isAutoBuilder' => 'false',
         'reconciled' => false,
         'dateTimeInLongFormat' => 1_469_067_229_602,
         'factoryId' => 1,
         'config' =>
           "!username admin privilege 15 role network-admin secret 0 admin\n"\
           '!username cvpadmin privilege 15 role network-admin secret 0 '\
           "arista123\nusername admin privilege 15 role network-admin secret 5"\
           " $1$7IJPvFto$.3IzcPDr5MJiBID8iCEFb1 \nusername cvpadmin privilege "\
           '15 role network-admin secret 5 '\
           "$1$e8zc.bhO$G1YLdeQGXLBS1J8T.oeJT/ \n! \n"\
           "management api http-commands\nno shutdown\n",
         'user' => 'cvpadmin',
         'note' => nil,
         'name' => 'cvp_base',
         'key' => 'configlet_17_22451036385055',
         'id' => 3,
         'type' => 'Static' },
       { 'isDefault' => 'no',
         'containerCount' => 0,
         'netElementCount' => 0,
         'isAutoBuilder' => 'false',
         'reconciled' => false,
         'dateTimeInLongFormat' => 1_488_799_943_078,
         'factoryId' => 1,
         'config' =>
           "interface Ethernet2\n   description Host esx3-10 managed by puppet"\
           " template cloudvision/esx_host.erb\n   ! Insert more configuration"\
           " here.\n   no shutdown\nend",
         'user' => 'cvpadmin',
         'note' => nil,
         'name' => 'dc1-rackb3-tor-port-2',
         'key' => 'configlet_1865173_17102357801295204',
         'id' => 3,
         'type' => 'Static' }]
    end
    let(:device) do
      { 'ipAddress' => '192.0.2.200',
        'modelName' => 'vEOS',
        'internalVersion' => '4.15.3F-2812776.4153F',
        'systemMacAddress' => '00:50:56:60:2c:a8',
        'memTotal' => 1_897_596,
        'bootupTimeStamp' => 1_473_364_832.23,
        'memFree' => 480_740,
        'architecture' => 'i386',
        'internalBuildId' => '34549125-b84f-41f0-b8bb-ce9d509814de',
        'hardwareRevision' => '',
        'fqdn' => 'veos-l-11.aristanetworks.com',
        'taskIdList' => [],
        'isDANZEnabled' => 'no',
        'isMLAGEnabled' => 'no',
        'ztpMode' => 'false',
        'complianceCode' => '0000',
        'version' => '4.15.3F',
        'complianceIndication' => 'NONE',
        'lastSyncUp' => 1_489_780_465_614,
        'tempAction' => nil,
        'serialNumber' => '',
        'key' => '00:50:56:60:2c:a8',
        'type' => 'netelement' }
    end

    before do
      allow(api).to receive(:get_configlets_by_device_id)
        .and_return(configlets_by_device)
      allow(api).to receive(:add_temp_action)
      allow(api).to receive(:save_topology_v2)
      stub_request(verb, url)
        .with(headers: good_headers)
        .to_return(body: resp_body)
    end

    describe '#apply_configlets_to_device' do
      let(:response) do
        api.apply_configlets_to_device('Puppet', '00:50:56:60:2c:a8',
                                       [{ 'name' => 'new_configlet',
                                          'key' => '12345678' }])
      end

      it 'returns nil' do
        expect(response).to be_nil
      end
    end

    describe '#remove_configlets_from_device' do
      let(:response) do
        api.remove_configlets_from_device('Puppet', '00:50:56:60:2c:a8',
                                          [{ 'name' => 'old_configlet',
                                             'key' => '12345678' }])
      end

      it 'returns nil' do
        expect(response).to be_nil
      end
    end
  end

  #
  # Provisioning
  #
  describe '#get_configlets_by_device_id' do
    let(:verb) { :get }
    let(:params) do
      '?netElementId=00:50:56:60:2c:a8&queryParam&startIndex=0&endIndex=0'
    end
    let(:url) do
      'https://cvp1.example.com/web/'\
      'provisioning/getConfigletsByNetElementId.do' + params
    end
    let(:resp_body) do
      '{"total":5,"configletList":[{"isDefault":"no","containerCount":0,'\
      '"netElementCount":0,"isAutoBuilder":"false","reconciled":false,'\
      '"dateTimeInLongFormat":1488396770908,"factoryId":1,'\
      '"config":"interface ethernet4\n   description Puppet was rot here\nend"'\
      ',"user":"cvpadmin","note":null,"name":"api_test_1","key":'\
      '"configlet_1866269_19351988468666178","id":3,"type":"Static"},'\
      '{"isDefault":"no","containerCount":0,"netElementCount":0,'\
      '"isAutoBuilder":"true","reconciled":false,"dateTimeInLongFormat":'\
      '1473364667402,"factoryId":1,"config":"","user":"cvpadmin","note":null,'\
      '"name":"configlet_ipam_builder","key":'\
      '"configletBuilderMapper_19_22638914337350","id":3,"type":"Builder"},'\
      '{"isDefault":"no","containerCount":0,"netElementCount":0,'\
      '"isAutoBuilder":"false","reconciled":false,'\
      '"dateTimeInLongFormat":1469068927533,"factoryId":1,"config":'\
      '"hostname veos-l-11\ninterface Management1\n'\
      'ip address 192.0.2.200/24\nip routing\n'\
      'ip route vrf default 0.0.0.0/0 192.0.2.254\n'\
      'ip name-server vrf default 192.0.2.254\n'\
      'ip domain-name aristanetworks.com\n","user":"cvpadmin","note":null,'\
      '"name":"configlet_ipam_builder_192.0.2.200_1",'\
      '"key":"configlet_70_24148965410223","id":3,"type":"Generated"},'\
      '{"isDefault":"no","containerCount":0,"netElementCount":0,'\
      '"isAutoBuilder":"false","reconciled":false,'\
      '"dateTimeInLongFormat":1469067229602,"factoryId":1,"config":'\
      '"!username admin privilege 15 role network-admin secret 0 admin\n'\
      '!username cvpadmin privilege 15 role network-admin secret 0 arista123\n'\
      'username admin privilege 15 role network-admin secret 5 '\
      '$1$7IJPvFto$.3IzcPDr5MJiBID8iCEFb1 \n'\
      'username cvpadmin privilege 15 role network-admin secret 5 '\
      '$1$e8zc.bhO$G1YLdeQGXLBS1J8T.oeJT/ \n! \nmanagement api http-commands\n'\
      'no shutdown\n","user":"cvpadmin","note":null,"name":"cvp_base",'\
      '"key":"configlet_17_22451036385055","id":3,"type":"Static"},'\
      '{"isDefault":"no","containerCount":0,"netElementCount":0,'\
      '"isAutoBuilder":"false","reconciled":false,'\
      '"dateTimeInLongFormat":1488799943078,"factoryId":1,"config":'\
      '"interface Ethernet2\n   description Host esx3-10 managed by puppet '\
      'template cloudvision/esx_host.erb\n'\
      '! Insert more configuration here.\n   no shutdown\nend",'\
      '"user":"cvpadmin","note":null,"name":"dc1-rackb3-tor-port-2",'\
      '"key":"configlet_1865173_17102357801295204","id":3,"type":"Static"}]}'
    end

    before do
      stub_request(verb, url)
        .with(headers: good_headers)
        .to_return(body: resp_body)
    end
    let(:response) do
      api.get_configlets_by_device_id('00:50:56:60:2c:a8')
    end
    it 'returns a list' do
      expect(response).to be_kind_of(Array)
    end
    it 'returns value of the configletList key' do
      expect(response).to eq(JSON.parse(resp_body)['configletList'])
    end
  end

  describe '#add_temp_action' do
    let(:verb) { :post }
    let(:param) { '?format=topology&queryParam&nodeId=root' }
    let(:url) do
      'https://cvp1.example.com/web/provisioning/addTempAction.do' + param
    end
    let(:resp_body) { fixture('addTempAction_response') }

    before do
      stub_request(verb, url)
        .with(headers: good_headers)
        .to_return(body: resp_body)
    end
    let(:response) do
      api.send(:add_temp_action, {})
    end
    it 'returns a hash' do
      expect(response).to be_kind_of(Hash)
    end
    it 'returns a response' do
      expect(response).to eq(JSON.parse(resp_body))
    end
  end

  describe '#save_topology_v2' do
    let(:verb) { :post }
    let(:url) do
      'https://cvp1.example.com/web/provisioning/v2/saveTopology.do'
    end
    let(:resp_body) do
      '{"data":{"taskIds":[],"status":"success"}}'
    end

    before do
      stub_request(verb, url)
        .with(headers: good_headers)
        .to_return(body: resp_body)
    end
    let(:response) do
      api.send(:save_topology_v2, {})
    end
    it 'returns a hash' do
      expect(response).to be_kind_of(Hash)
    end
    it 'returns a response' do
      expect(response).to eq(JSON.parse(resp_body))
    end
  end

  #
  # Tasks
  #

  describe '#get_task_by_id' do
    let(:verb) { :get }
    let(:params) { '?taskId=3' }
    let(:url) do
      'https://cvp1.example.com/web/task/getTaskById.do' + params
    end

    context 'with a valid task_id' do
      let(:resp_body) { fixture('addTempAction_response') }
      before do
        stub_request(verb, url)
          .with(headers: good_headers)
          .to_return(body: resp_body)
      end
      let(:response) do
        api.get_task_by_id(3)
      end
      it 'returns a hash' do
        expect(response).to be_kind_of(Hash)
      end
      it 'returns a response' do
        expect(response).to eq(JSON.parse(resp_body))
      end
    end

    context 'with invalid task_id' do
      let(:resp_body) do
        '{"errorCode":"142WF606","errorMessage":"Invalid WorkOrderId"}'
      end
      before do
        stub_request(verb, url)
          .with(headers: good_headers)
          .to_return(body: resp_body)
      end
      let(:response) do
        api.get_task_by_id(3)
      end
      it 'returns nil' do
        expect(response).to be_nil
      end
    end
  end

  describe '#get_pending_tasks_by_device' do
    let(:verb) { :get }
    let(:params) { '?queryparam=Pending&startIndex=0&endIndex=0' }
    let(:url) { 'https://cvp1.example.com/web/task/getTasks.do' + params }
    let(:resp_body) { %({"total":0,"data":[]}) }

    before do
      stub_request(verb, url)
        .with(headers: good_headers)
        .to_return(body: resp_body)
    end
    let(:response) do
      api.get_pending_tasks_by_device('device-1.example.com')
    end
    it 'returns a list of task objects' do
      expect(response).to be_kind_of(Array)
    end
    it 'returns the "data" value from the response' do
      expect(response).to eq(JSON.parse(resp_body)['data'])
    end
  end

  describe '#add_note_to_task' do
    let(:verb) { :post }
    let(:params) { '?workOrderId=3&note=text' }
    let(:url) { 'https://cvp1.example.com/web/task/addNoteToTask.do' + params }
    let(:resp_body) { %({ "data": "Success" }) }

    before do
      stub_request(verb, url)
        .with(headers: good_headers)
        .to_return(body: resp_body)
    end
    let(:response) do
      api.add_note_to_task(3, 'text')
    end
    it 'returns a Hash' do
      expect(response).to be_kind_of(Hash)
    end
  end

  describe '#execute_task' do
    let(:verb) { :post }
    let(:url) { 'https://cvp1.example.com/web/task/executeTask.do' }
    let(:resp_body) { %({ "data": "Success" }) }

    before do
      stub_request(verb, url)
        .with(headers: good_headers,
              body: '{"data":[3]}')
        .to_return(body: resp_body)
    end
    let(:response) do
      api.execute_task(3)
    end
    it 'returns a Hash' do
      expect(response).to be_kind_of(Hash)
    end
  end
end
