# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

class AccessControlStep < BasicStep
  def initialize(step = 'access-control',
                 title = "Access Control",
                 summary = "Who can access the item",
                 template = 'access_control')
    super
  end

  def execute context
    media_object = context[:media_object]

    user = User.where({ Devise.authentication_keys.first => context[:user]}).first
    ability = context[:ability]
    ability ||= Ability.new(user)
    unless ability.can? :update_access_control, media_object
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
                media_object.governing_policies += [ Lease.create(begin_time: begin_time, end_time: end_time, inherited_read_users: [val]) ]
              rescue Exception => e
                context[:error] = e.message
              end
            else
              media_object.read_users += [val]
            end
          elsif title=='ipaddress'
            if ( IPAddr.new(val) rescue false )
              if create_lease
                begin
                  media_object.governing_policies += [ Lease.create(begin_time: begin_time, end_time: end_time, inherited_read_groups: [val]) ]
                rescue Exception => e
                  context[:error] = e.message
                end
              else
                media_object.read_groups += [val]
              end
            else
              context[:error] = "IP Address #{val} is invalid. Valid examples: 124.124.10.10, 124.124.0.0/16, 124.124.0.0/255.255.0.0"
            end
          else
            if create_lease
              begin
                media_object.governing_policies += [ Lease.create(begin_time: begin_time, end_time: end_time, inherited_read_groups: [val]) ]
              rescue Exception => e
                context[:error] = e.message
              end
            else
              media_object.read_groups += [val]
            end
          end
        else
          context[:error] = "#{title.titleize} can't be blank."
        end
      end
      if context["remove_#{title}"].present?
        limited_access_submit = true
        if ["group", "class", "ipaddress"].include? title
          media_object.read_groups -= [context["remove_#{title}"]]
        else
          media_object.read_users -= [context["remove_#{title}"]]
        end
      end
    end
    if context['remove_lease'].present?
      limited_access_submit = true
      lease = Lease.find(context['remove_lease'])
      media_object.governing_policies.delete(lease)
      lease.destroy
    end

    unless limited_access_submit
      media_object.visibility = context[:visibility] unless context[:visibility].blank?
      media_object.hidden = context[:hidden] == "1"
      if media_object.cdl_enabled?
        lending_period = build_lending_period(context)
        if lending_period.positive?
          media_object.lending_period = lending_period
        elsif lending_period.zero?
          context[:error] = "Lending period must be greater than 0."
        end
      end
    end

    context
  end

  private

    def build_lending_period(context)
      lending_period = 0
      errors = []
      d = context["add_lending_period_days"].to_i
      h = context["add_lending_period_hours"].to_i
      d.negative? ? errors.append("Lending period days needs to be a positive integer.") : lending_period += d.days
      h.negative? ? errors.append("Lending period hours needs to be a positive integer.") : lending_period += h.hours

      context[:error] = errors.join(' ') if errors.present?
      lending_period.to_i
    rescue
      0
    end
end
