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
  let(:cvp) { CvpClient.new }
  # Use for debugging
  # let(:cvp) do
  #   CvpClient.new(filename: 'STDOUT', file_log_level: Logger::DEBUG) }
  # end

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
      .to_return(status: 200,
                 body: login_body,
                 headers: { 'set-cookie' => set_cookie })
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
        expect(cvp.connect(['cvp1.example.com'], 'cvpadmin', 'arista123'))
          .to be_nil
      end
      before(:each) do
        cvp.connect(['cvp1.example.com'], 'cvpadmin', 'arista123')
      end

      it 'sets session data' do
        expect(cvp.instance_variable_get(:@session)).not_to be_nil
        expect(cvp.instance_variable_get(:@session)).to eq(session_id)
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
                                         .cookies)).to include(session_id)
      end
    end

    context 'using HTTP' do
      before(:each) do
        stub_request(:post, 'http://cvp1.example.com/web/login/authenticate.do')
          .with(headers: dflt_headers)
          .to_return(status: 200,
                     body: login_body,
                     headers: { 'set-cookie' => set_cookie })

        cvp.connect(['cvp1.example.com'], 'cvpadmin', 'arista123',
                    protocol: 'http')
      end
      it 'sets session data' do
        expect(cvp.instance_variable_get(:@session)).not_to be_nil
        expect(cvp.instance_variable_get(:@session)).to eq(session_id)
      end
      it 'sets the protocol' do
        expect(cvp.protocol).to eq('http')
      end
      it 'sets the port' do
        expect(cvp.port).to eq(80)
      end
      it 'sets the connect_timeout' do
        expect(cvp.connect_timeout).to eq(10)
      end
      it 'sets the session_id in the cookies' do
        expect(HTTP::Cookie.cookie_value(cvp.instance_variable_get(:@cookies)
                                         .cookies))
          .to include(session_id)
      end
    end

    context 'with bad authdata' do
      let(:set_cookie_unauth) do
        ['JSESSIONID=6C44248299845CD5250B29AB14CBD6F6;'\
                                 ' Path=/web/; HttpOnly']
      end
      before(:each) do
        stub_request(:post, 'https://cvp2.example.com/web/login/authenticate.do')
          .with(body: '{"userId":"cvpadmin","password":"idontknow"}',
                headers: dflt_headers)
          .to_return(status: 200,
                     body: '{"errorCode":"112498",'\
                           '"errorMessage":"Unauthorized User"}',
                     headers: { 'set-cookie' => set_cookie_unauth })
      end
      it 'raises error' do
        expect { cvp.connect(['cvp2.example.com'], 'cvpadmin', 'idontknow') }
          .to raise_error(CvpApiError)
        # .to raise_error(CvpLoginError)
      end
    end

    context 'with bad protocol' do
      let(:set_cookie_unauth) do
        ['JSESSIONID=6C44248299845CD5250B29AB14CBD6F6;'\
                                 ' Path=/web/; HttpOnly']
      end
      before(:each) do
        stub_request(:post, 'https://cvp2.example.com/web/login/authenticate.do')
          .with(body: '{"userId":"cvpadmin","password":"idontknow"}',
                headers: dflt_headers)
          .to_return(status: 200,
                     body: '{"errorCode":"112498",'\
                           '"errorMessage":"Unauthorized User"}',
                     headers: { 'set-cookie' => set_cookie_unauth })
      end
      it 'raises error' do
        expect do
          cvp.connect(['cvp1.example.com'], 'cvpadmin', 'idontknow',
                      protocol: 'ftp')
        end
          .to raise_error(ArgumentError)
      end
    end

    context 'after timeout (execution expired)' do
      before(:each) do
        stub_request(:post, 'https://cvp2.example.com/web/login/authenticate.do')
          .with(body: '{"userId":"cvpadmin","password":"idontknow"}',
                headers: dflt_headers)
          .to_timeout
      end
      it 'raises error' do
        expect { cvp.connect(['cvp2.example.com'], 'cvpadmin', 'idontknow') }
          .to raise_error(CvpLoginError)
      end
    end
  end

  describe '#get' do
    before(:each) do
      # HTTP Login
      stub_request(:post, 'http://cvp1.example.com/web/login/authenticate.do')
        .with(headers: dflt_headers)
        .to_return(status: 200,
                   body: login_body,
                   headers: { 'set-cookie' => set_cookie })

      # HTTPS Login
      stub_request(:post, 'https://cvp1.example.com/web/login/authenticate.do')
        .with(headers: dflt_headers)
        .to_return(status: 200,
                   body: login_body,
                   headers: { 'set-cookie' => set_cookie })
    end

    before(:each) do
      cvp.connect(['cvp1.example.com'], 'cvpadmin', 'arista123')
    end

    context 'HTTP without parameters (Example: getCvpInfo)' do
      let(:body) { %({ "version": "2016.1.1" }) }
      before do
        stub_request(:get, 'https://cvp1.example.com/web/cvpInfo/getCvpInfo.do')
          .with(headers: good_headers)
          .to_return(status: 200,
                     body: body,
                     headers: { 'date' => 'Mon, 09 Jan 2017 14:32:30 GMT',
                                'server' => 'nginx/1.8.1',
                                'connection' => 'keep-alive',
                                'content-length' => '22',
                                'content-type' => content_type })
      end

      it 'returns a parsable JSON response' do
        response = cvp.get('/cvpInfo/getCvpInfo.do')
        expect(response).to be_kind_of(Hash)
        expect(response).to eq(JSON.parse(body))
      end
    end

    context 'HTTPS with parameters (Example: getUsers)' do
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
      before do
        cvp.connect(['cvp1.example.com'], 'cvpadmin', 'arista123',
                    protocol: 'https')
        stub_request(:get, 'https://cvp1.example.com/web/user/getUsers.do?endIndex=0&queryparam&startIndex=0')
          .with(headers: good_headers)
          .to_return(status: 200,
                     body: body,
                     headers: { 'date' => 'Mon, 09 Jan 2017 14:32:30 GMT',
                                'server' => 'nginx/1.8.1',
                                'connection' => 'keep-alive',
                                'content-length' => '22',
                                'content-type' => content_type })
      end

      it 'returns a parsable JSON response' do
        response = cvp.get('/user/getUsers.do',
                           data: { queryparam: nil,
                                   startIndex: 0, endIndex: 0 })
        expect(response).to be_kind_of(Hash)
        expect(response).to eq(JSON.parse(body))
      end
    end

    context 'timeout' do
      # Verbose debug settings
      # let(:cvp) do
      #   CvpClient.new(filename: 'STDOUT', file_log_level: Logger::DEBUG) }
      # end
      let(:cvp2) { CvpClient.new }
      before(:each) do
        cvp2.connect(['cvp1.example.com'], 'cvpadmin', 'idontknow')
        stub_request(:get, 'https://cvp1.example.com/web/timeout.do')
          .to_timeout.times(4).then
          .to_return(status: 200,
                     body: '{"result": "success"}')
      end
      it 'retries then raises error' do
        expect { cvp2.get('/timeout.do') }.to raise_error(CvpRequestError)
        expect { cvp2.get('/timeout.do') }.to raise_error(CvpRequestError)
        expect { cvp2.get('/timeout.do') }.to raise_error(CvpRequestError)
        expect { cvp2.get('/timeout.do') }.to raise_error(CvpRequestError)
        expect(cvp2.get('/timeout.do')).to eq('result' => 'success')
      end
    end

    context 'with invalid endpoint (Error 404)' do
      let(:body) { fixture('404_response') }

      before do
        stub_request(:get, 'https://cvp1.example.com/web/user/getUs.do')
          .with(headers: good_headers)
          .to_return(status: 400,
                     body: body,
                     headers: { 'date' => 'Mon, 09 Jan 2017 14:32:30 GMT',
                                'server' => 'nginx/1.8.1',
                                'connection' => 'keep-alive',
                                'content-length' => '22',
                                'content-type' => content_type })
      end

      it 'raises CvpRequestError' do
        expect { cvp.get('/user/getUs.do') }
          .to raise_error(CvpRequestError,
                          %r{HTTP Status 404 - /web/user/getUs.do})
      end
    end

    context 'with session logged out (302 redirect to login)' do
      WebMock.reset!
      let(:body) { %({ "version": "2016.1.1" }) }
      let(:session_logged_out) do
        { status: 302,
          headers: { 'date' => 'Mon, 09 Jan 2017 14:32:30 GMT',
                     'server' => 'nginx/1.8.1',
                     'connection' => 'keep-alive',
                     'content-length' => '22',
                     'content-type' => content_type } }
      end

      let(:normal) do
        { status: 200,
          body: body,
          headers: { 'date' => 'Mon, 09 Jan 2017 14:32:30 GMT',
                     'server' => 'nginx/1.8.1',
                     'connection' => 'keep-alive',
                     'content-length' => '22',
                     'content-type' => content_type } }
      end
      let(:cvp3) { CvpClient.new }
      let(:auth_url) { 'https://cvp1.example.com/web/login/authenticate.do' }
      let(:test_url) { 'https://cvp1.example.com/web/cvpInfo/getCvpInfo.do' }
      before(:each) do
        WebMock.reset!
        stub_request(:post, 'https://cvp1.example.com/web/login/authenticate.do')
          .with(headers: dflt_headers)
          .to_return(status: 200,
                     body: login_body,
                     headers: { 'set-cookie' => set_cookie })
      end

      it 'succeeds after 2 re-login + retry attempts' do
        # Return a redirect to login, then return a regular response
        stub_request(:get, test_url)
          .with(headers: good_headers)
          .to_return(session_logged_out).times(2).then
          .to_return(normal)
        cvp3.connect(['cvp1.example.com'], 'cvpadmin', 'arista123')

        expect(WebMock).to have_requested(:post, auth_url)
          .once
        expect(cvp3.get('/cvpInfo/getCvpInfo.do')).to eq(JSON.parse(body))
        # Original + 2 additional tries
        expect(WebMock).to have_requested(:post, auth_url)
          .times(3)
        # Original + 1 unsuccessful retry + successful retry
        expect(WebMock).to have_requested(:get, test_url)
          .times(3)
      end

      it 'raises CvpSessionLogOutError after 3 attempts' do
        # continuously return a redirect to login
        stub_request(:get, test_url)
          .with(headers: good_headers)
          .to_return(session_logged_out)
        cvp3.connect(['cvp1.example.com'], 'cvpadmin', 'arista123')
        expect(WebMock).to have_requested(:post, auth_url)
          .times(1)
        expect { cvp3.get('/cvpInfo/getCvpInfo.do') }
          .to raise_error(CvpSessionLogOutError,
                          /No more retries/)
        # Original + 2 additional tries
        expect(WebMock).to have_requested(:post, auth_url)
          .times(3)
        # Original + 2 retries
        expect(WebMock).to have_requested(:get, test_url)
          .times(3)
      end
    end
  end

  describe '#post' do
    let(:return_body) { '{"some":"data"}' }
    before(:each) do
      # HTTP Login
      stub_request(:post, 'https://cvp1.example.com/web/login/authenticate.do')
        .with(headers: dflt_headers)
        .to_return(status: 200,
                   body: login_body,
                   headers: { 'set-cookie' => set_cookie })

      # POST responder
      stub_request(:post, 'https://cvp1.example.com/web/test/endpoint.do')
        .with(body: '{"some":"data"}',
              headers: good_headers)
        .to_return(status: 200,
                   body: return_body,
                   headers: { 'set-cookie' => set_cookie })
    end

    before(:each) do
      cvp.connect(['cvp1.example.com'], 'cvpadmin', 'arista123')
    end

    context 'basic' do
      it 'returns valid data' do
        response = cvp.post('/test/endpoint.do', body: '{"some":"data"}')
        expect(response).to be_kind_of(Hash)
        expect(response).to eq(JSON.parse(return_body))
      end
    end
  end
end
