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

# This module contains methods which transform stored values for use either on the MediaObject or the SpeedyAF presenter
module MediaObjectBehavior

  def as_json(options={})
    {
      id: id,
      title: title,
      collection: collection.name,
      collection_id: collection.id,
      unit: collection.unit,
      main_contributors: creator,
      publication_date: date_created,
      published_by: avalon_publisher,
      published: published?,
      summary: abstract,
      visibility: visibility,
      read_groups: read_groups,
      lending_period: lending_period,
      lending_status: lending_status,
    }.merge(to_ingest_api_hash(options.fetch(:include_structure, false)))
  end

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

  def has_captions
    sections.any? { |mf| mf.has_captions? }
  end

  def has_transcripts
    sections.any? { |mf| mf.has_transcripts? }
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
