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
    limited_access_submit = false
    ["group", "class", "user", "ipaddress"].each do |title|
      if context["submit_add_#{title}"].present?
        limited_access_submit = true
        begin_time = context["add_#{title}_begin"].blank? ? nil : context["add_#{title}_begin"] 
        end_time = context["add_#{title}_end"].blank? ? nil : context["add_#{title}_end"]
        create_lease = begin_time.present? || end_time.present?
        if context["add_#{title}"].present?
          val = context["add_#{title}"].strip
          if title=='user'
            if create_lease
              begin
                mediaobject.governing_policies += [ Lease.create(begin_time: begin_time, end_time: end_time, read_users: [val]) ]
              rescue Exception => e
                context[:error] = e.message
              end
            else
              mediaobject.read_users += [val]
            end
          elsif title=='ipaddress'
            if ( IPAddr.new(val) rescue false )
              if create_lease
                begin
                  mediaobject.governing_policies += [ Lease.create(begin_time: begin_time, end_time: end_time, read_groups: [val]) ]
                rescue Exception => e
                  context[:error] = e.message
                end
              else
                mediaobject.read_groups += [val]
              end
            else
              context[:error] = "IP Address #{val} is invalid. Valid examples: 124.124.10.10, 124.124.0.0/16, 124.124.0.0/255.255.0.0"
            end
          else
            if create_lease
              begin
                mediaobject.governing_policies += [ Lease.create(begin_time: begin_time, end_time: end_time, read_groups: [val]) ]
              rescue Exception => e
                context[:error] = e.message
              end
            else
              mediaobject.read_groups += [val]
            end
          end
        else
          context[:error] = "#{title.titleize} can't be blank."
        end
      end
      if context["remove_#{title}"].present?
        limited_access_submit = true
        if ["group", "class", "ipaddress"].include? title
          mediaobject.read_groups -= [context["remove_#{title}"]]
        else
          mediaobject.read_users -= [context["remove_#{title}"]]
        end
      end
    end
    if context['remove_lease'].present?
      limited_access_submit = true
      lease = Lease.find( context['remove_lease'] )
      mediaobject.governing_policies.delete( lease )
      lease.destroy
    end
    unless limited_access_submit
      mediaobject.visibility = context[:visibility] unless context[:visibility].blank? 
      mediaobject.hidden = context[:hidden] == "1"
    end
    mediaobject.save!

    #Setup these values in the context because the edit partial is being rendered without running the controller's #edit (VOV-2978)
    mediaobject.reload
    context[:users] = mediaobject.read_users
    context[:groups] = mediaobject.read_groups
    context[:virtual_groups] = mediaobject.virtual_read_groups
    context[:ip_groups] = mediaobject.ip_read_groups
    context[:group_leases] = mediaobject.governing_policies.to_a.select { |p| p.class==Lease && p.lease_type=="local" }
    context[:user_leases] = mediaobject.governing_policies.to_a.select { |p| p.class==Lease && p.lease_type=="user" }
    context[:virtual_leases] = mediaobject.governing_policies.to_a.select { |p| p.class==Lease && p.lease_type=="external" }
    context[:ip_leases] = mediaobject.governing_policies.to_a.select { |p| p.class==Lease && p.lease_type=="ip" }
    context[:addable_groups] = Admin::Group.non_system_groups.reject { |g| context[:groups].include? g.name }
    context[:addable_courses] = Course.all.reject { |c| context[:virtual_groups].include? c.context_id }
    context
  end
end
