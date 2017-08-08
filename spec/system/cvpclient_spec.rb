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

RSpec.describe CvpClient do
  let(:cvp_ip) { '10.81.111.62' }
  WebMock.disable_net_connect!(allow: '10.81.111.62')

  let(:cvp) { CvpClient.new }
  # Use for debugging
  let(:cvp) do
    CvpClient.new(filename: 'STDOUT', file_log_level: Logger::DEBUG)
  end

  context 'before #connect' do
    subject(:cvp) { CvpClient.new }
    it 'instance has no session data' do
      expect(cvp.instance_variable_get(:@session)).to be_nil
    end

    it '#get raises an error' do
      expect { cvp.get('/user/getUs.do') }
        .to raise_error(RuntimeError,
                        'No valid session to a CVP node. Use #connect()')
    end
  end

  describe '#connect' do
    context 'with defaults (https)' do
      it 'returns nil' do
        expect(cvp.connect([cvp_ip], 'cvpadmin', 'cvp123'))
          .to be_nil
      end
      before(:each) do
        cvp.connect([cvp_ip], 'cvpadmin', 'cvp123')
      end

      it 'sets session data' do
        expect(cvp.instance_variable_get(:@session)).not_to be_nil
      end
      it 'sets the protocol' do
        expect(cvp.protocol).to eq('https')
      end
      it 'sets the port' do
        expect(cvp.port).to eq(443)
      end
      it 'sets the connect_timeout' do
        expect(cvp.connect_timeout).to eq(10)
      end
      it 'sets the session_id in the cookies' do
        expect(HTTP::Cookie.cookie_value(cvp.instance_variable_get(:@cookies)
                                         .cookies)).to include('session_id')
      end
    end

    context 'with bad authdata' do
      it 'raises error' do
        expect { cvp.connect([cvp_ip], 'cvpadmin', 'idontknow') }
          .to raise_error(CvpLoginError)
      end
    end
  end

  describe '#get' do
    before(:each) do
      cvp.connect([cvp_ip], 'cvpadmin', 'cvp123')
    end

    context 'without parameters (Example: getCvpInfo)' do
      let(:body) { %({ "version": "2017.1.0.1" }) }

      it 'returns a parsable JSON response' do
        response = cvp.get('/cvpInfo/getCvpInfo.do')
        expect(response).to be_kind_of(Hash)
        expect(response).to include(JSON.parse(body))
      end
    end

    context 'with parameters (Example: getUsers)' do
      let(:body) do
        %({
                            "total": 1,
                            "users": [
                              {
                                "userId": "cvpadmin",
                                "firstName": null,
                                "email": "jere@arista.com",
                                "lastAccessed": 1483974875111,
                                "userStatus": "Enabled",
                                "currentStatus": "Online",
                                "contactNumber": null,
                                "factoryId": 1,
                                "lastName": null,
                                "password": null,
                                "id": 28
                              }
                            ],
                            "roles": {
                              "cvpadmin": [
                                "network-admin"
                              ]
                            }
                          })
      end

      it 'returns a parsable JSON response' do
        response = cvp.get('/user/getUsers.do',
                           data: { queryparam: nil,
                                   startIndex: 0, endIndex: 0 })
        expect(response).to be_kind_of(Hash)
        expect(response).to include('total', 'users', 'roles')
        expect(response['users'][0]).to include('currentStatus', 'email',
                                                'firstName', 'lastName',
                                                'password', 'lastAccessed',
                                                'id', 'factoryId')
      end
    end

    context 'with invalid endpoint (Error 404)' do
      let(:body) { fixture('404_response') }

      it 'raises CvpRequestError' do
        expect { cvp.get('/user/getUs.do') }
          .to raise_error(CvpRequestError,
                          /HTTP Status 404 - Invalid endpoint/)
      end
    end
  end

  describe '#post' do
    let(:return_body) { '{"some":"data"}' }

    before(:each) do
      cvp.connect([cvp_ip], 'cvpadmin', 'cvp123')
      data = cvp.get('/label/getLabels.do',
                     data: { module: 'LABEL', type: 'ALL',
                             startIndex: 0, endIndex: 0 })
      data['labels'].each do |label|
        if label['name'] == 'basic_post'
          cvp.post('/label/deleteLabel.do',
                   body: "{ \"data\": [\"#{label['key']}\"] }")
        end
      end
    end

    context 'basic' do
      let(:body) do
        '{ "name": "basic_post", "note": "system test", "type": "CUSTOM"}'
      end
      it 'returns valid data' do
        response = cvp.post('/label/addLabel.do',
                            body: body)
        # Type: Container, Product, CUSTOM
        expect(response).to be_kind_of(Hash)
        expect(response).to include('name' => 'basic_post',
                                    'note' => 'system test',
                                    'type' => 'CUSTOM')
        expect(response).to include('key', 'name', 'note', 'type', 'factoryId',
                                    'id')
      end
    end
  end
end
