# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

require 'rails_helper'

describe 'mejs', type: :request do
  it 'stores the version of me.js supplied' do
    get '/mejs/4'
    expect(request.env['rack.session']['mejs_version']).to eq 4
  end

  it 'redirects to root' do
    expect(get '/mejs/4').to redirect_to(root_path)
  end

  it 'sets a flash message' do
    get '/mejs/4'
    expect(flash[:notice]).not_to be_empty
  end
end
