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
# @author Jere Julian <jere@arista.com>
#

# Error logging in to CVP
class CvpLoginError < StandardError
  attr_reader :code, :msg
  def initialize(msg = 'Unknown error')
    @msg = msg
    super("ERROR: #{msg}")
  end
end

# General error with a CVP HTTP request
class CvpRequestError < StandardError
  attr_reader :code, :msg
  def initialize(code = nil, msg = 'Unknown error')
    @code = code
    @msg = msg
    super("ERROR: #{code} - #{msg}")
  end
end

# Session to the CVP node(s) has been logged out
class CvpSessionLogOutError < StandardError
  def initialize(msg = 'Unknown error')
    super(msg)
  end
end

# General error for CVP requests
class CvpApiError < StandardError
  def initialize(msg = 'Unknown error')
    super("ERROR: #{msg}")
  end
end
