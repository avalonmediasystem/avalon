# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

describe 'redirect', type: :request do
  it 'stores url to redirect to when unauthorized and needing to authenticate (#authorize!)' do
    get '/admin/migration_report'
    expect(request.env['rack.session']['previous_url']).to eq '/admin/migration_report'
    expect(response).to render_template('errors/restricted_pid')
  end

  it 'stores url to redirect to when needing to authenticate (#authenticate_user!)' do
    get '/bookmarks'
    expect(request.env['rack.session']['previous_url']).to eq '/bookmarks'
    expect(response).to redirect_to(/#{Regexp.quote(new_user_session_path)}\?url=.*/)
  end
end
