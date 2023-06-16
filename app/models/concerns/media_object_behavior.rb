# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

# This module contains methods which transform stored values for use either on the MediaObject or the SpeedyAF presenter
module MediaObjectBehavior
  def published?
    !avalon_publisher.blank?
  end

  def access_text
    actors = []
    if visibility == "public"
      actors << "the public"
    else
      actors << "collection staff" if visibility == "private"
      actors << "specific users" if read_users.any? || leases('user').any?

      if visibility == "restricted"
        actors << "logged-in users"
      elsif virtual_read_groups.any? || local_read_groups.any? || leases('external').any? || leases('local').any?
        actors << "users in specific groups"
      end

      actors << "users in specific IP Ranges" if ip_read_groups.any? || leases('ip').any?
    end

    "This item is accessible by: #{actors.join(', ')}."
  end

  # CDL methods
  def lending_status
    Checkout.active_for_media_object(id).any? ? "checked_out" : "available"
  end

  def return_time
    Checkout.active_for_media_object(id).first&.return_time
  end

  def cdl_enabled?
    collection&.cdl_enabled?
  end

  def current_checkout(user_id)
    checkouts = Checkout.active_for_media_object(id)
    checkouts.select{ |ch| ch.user_id == user_id  }.first
  end
end
