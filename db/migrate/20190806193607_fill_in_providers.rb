# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

class FillInProviders < ActiveRecord::Migration[5.2]
  def change
    User.where('provider IS NULL').find_each do |user|
      identity = Identity.find_by(email: user.email) if user.email
      if identity
        user.update_attribute(:provider, 'identity')
      elsif user.uid.present?
        user.update_attribute(:provider, Avalon::Authentication::VisibleProviders.first[:provider])
      else
        user.update_attribute(:provider, 'local')
      end
    end
  end
end
