# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

class Users::SessionsController < Devise::SessionsController
  def new
    if Avalon::Authentication::VisibleProviders.length == 1
      redirect_to user_omniauth_authorize_path(Avalon::Authentication::VisibleProviders.first[:provider], params)
    else
      super
    end
  end

  def destroy
    StreamToken.logout! session
    super
    flash[:success] = flash[:notice]
    flash[:notice] = nil
  end
end
