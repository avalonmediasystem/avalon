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
    ["group", "class", "user"].each do |title|
      if context["submit_add_#{title}"].present?
        if context["add_#{title}"].present?
          if ["group", "class"].include? title
            mediaobject.read_groups += [context["add_#{title}"].strip]
          else
            mediaobject.read_users += [context["add_#{title}"].strip]
          end
        else
          context[:error] = "#{title.titleize} can't be blank."
        end
      end
      
      if context["remove_#{title}"].present?
        if ["group", "class"].include? title
          mediaobject.read_groups -= [context["remove_#{title}"]]
        else
          mediaobject.read_users -= [context["remove_#{title}"]]
        end
      end
    end

    mediaobject.visibility = context[:visibility] unless context[:visibility].blank? 

    mediaobject.hidden = context[:hidden] == "1"

    mediaobject.save

    #Setup these values in the context because the edit partial is being rendered without running the controller's #edit (VOV-2978)
    mediaobject.reload
    context[:users] = mediaobject.read_users
    context[:groups] = mediaobject.read_groups
    context[:virtual_groups] = mediaobject.virtual_read_groups
    context[:addable_groups] = Admin::Group.non_system_groups.reject { |g| context[:groups].include? g.name }
    context[:addable_courses] = Course.all.reject { |c| context[:virtual_groups].include? c.context_id }

    context
  end
end
