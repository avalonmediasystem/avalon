# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

class AccessControlStep < Avalon::Workflow::BasicStep
  def initialize(step = 'access-control', 
                 title = "Access Control", 
                 summary = "Who can access the item", 
                 template = 'access_control')
    super
  end

  def execute context
    mediaobject = context[:mediaobject]

    user = User.where({ Devise.authentication_keys.first => context[:user]}).first
    ability = context[:ability]
    ability ||= Ability.new(user)
    unless ability.can? :update_access_control, mediaobject
      return context
    end

    # Limited access stuff
    mediaobject.read_groups -= [context[:remove_group]] if context[:remove_group].present?
    mediaobject.read_users -= [context[:remove_user]] if context[:remove_user].present?
    mediaobject.read_groups -= [context[:remove_class]] if context[:remove_class].present?
    mediaobject.read_groups += [context[:add_group]] if context[:submit_add_group].present?
    mediaobject.read_users += [context[:add_user]] if context[:submit_add_user].present?
    mediaobject.read_groups += [context[:add_class]] if context[:submit_add_class].present?

    mediaobject.visibility = context[:visibility] unless context[:visibility].blank? 

    mediaobject.hidden = context[:hidden] == "1"

    mediaobject.save
    context
  end
end
