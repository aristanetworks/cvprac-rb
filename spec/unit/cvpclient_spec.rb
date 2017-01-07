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
  # subject(:cvp) { CvpClient.new }
  let(:accept_encoding) { 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3' }
  let(:user_agent) { 'rspec (x86_64-darwin14) cvprac-rb/0.1.0' }
  let(:dflt_headers) do
    { 'Accept' => 'application/json',
      'Accept-Encoding' => accept_encoding,
      'Content-Type' => 'application/json',
      'User-Agent' => user_agent }
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

  let(:login_body) { fixture('login_body') }

  before(:each) do
    # stub_request(:any, "cvp1.example.com")
    # with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
    # require 'json'
    # print "BODY: "+JSON.parse(login_body)+"\n"
    stub_request(:post, 'http://cvp1.example.com/web/login/authenticate.do')
      .with(headers: dflt_headers)
      .to_return(status: 200,
                 # body: "#{login_body}",
                 body: login_body,
                 headers: { 'set-cookie' => set_cookie })
  end

  context 'before #connect' do
    subject(:cvp) { CvpClient.new }
    it 'instance has no session data' do
      expect(cvp.instance_variable_get(:@session)).to be_nil
    end
  end

  describe '#connect' do
    context 'with defaults (http)' do
      subject { cvp.connect(['cvp1.example.com'], 'cvpadmin', 'arista123') }
      it { is_expected.to be_nil }
      before(:each) do
        cvp.connect(['cvp1.example.com'], 'cvpadmin', 'arista123')
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
                                         .cookies)).to include(session_id)
      end
    end

    context 'using HTTPS' do
      before(:each) do
        stub_request(:post, 'https://cvp1.example.com/web/login/authenticate.do')
          .with(headers: dflt_headers)
          .to_return(status: 200,
                     body: login_body,
                     headers: { 'set-cookie' => set_cookie })

        cvp.connect(['cvp1.example.com'], 'cvpadmin', 'arista123',
                    10, 'https')
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
        stub_request(:post, 'http://cvp2.example.com/web/login/authenticate.do')
          .with(body: '{"userId":"cvpadmin","password":"idontknow"}',
                headers: dflt_headers)
          .to_return(status: 200,
                     body: '{"errorCode":"112498",'\
                           '"errorMessage":"Unauthorized User"}',
                     headers: { 'set-cookie' => set_cookie_unauth })
      end
      # subject { cvp.connect(['cvp2.example.com'], 'cvpadmin', 'idontknow') }
      # it { is_expected.to raise_error(CvpApiError) }
      it 'raises error' do
        expect { cvp.connect(['cvp2.example.com'], 'cvpadmin', 'idontknow') }
          .to raise_error(CvpLoginError)
      end
    end
  end
end
