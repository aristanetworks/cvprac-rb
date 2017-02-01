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
      .to_return(status: 200,
                 body: login_body,
                 headers: { 'set-cookie' => set_cookie })
    cvp.connect(['cvp1.example.com'], 'cvpadmin', 'arista123')
  end

  let(:api) { CvpApi.new(cvp) }

  describe '#get_cvp_info' do
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
    let(:response) { api.get_cvp_info }
    it 'returns a hash' do
      expect(response).to be_kind_of(Hash)
    end
    it 'returns the CVP version' do
      expect(response).to eq(JSON.parse(body))
    end
  end
end
