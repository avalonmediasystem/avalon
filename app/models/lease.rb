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

# Base Class for controlling access to Avalon content or groups via date restricted groups (Lease)
# @since 5.0.0
# @attr [DateTime] begin_time The date and time a lease begins
#                  Set to today on save if it is has not been set
#                  Always set to the supplied date (or default of today) and 00:00:00 UTC for the time on save (start of that day UTC time)
# @attr [DateTime] end_time The date and time a lease ends
#                  Must be set to save the object
#                  Always set to the supplied date and 23:59:59 UTC for the time on save (end of the day).
class Lease < ActiveFedora::Base
  before_save :apply_default_begin_time, :ensure_end_time_present, :validate_dates, :format_times

  has_and_belongs_to_many :media_objects, class_name: 'MediaObject', property: :has_member, inverse_of: :is_governed_by

  has_metadata name: 'inheritedRights', type: Hydra::Datastream::InheritableRightsMetadata
  has_metadata name: 'descMetadata', type: ActiveFedora::SimpleDatastream do |sds|
    sds.field :begin_time, :time
    sds.field :end_time, :time
  end
  has_attributes :begin_time, :end_time, datastream: :descMetadata, multiple: false

  delegate :read_groups, :read_groups=, :read_users, :read_users=, to: :inheritedRights

  # Determines if the lease is currently active (today is between the begin and end time)
  # @return [Boolean] returns true if the lease is active
  def lease_is_active?
    Date.today >= begin_time && Date.today <= end_time
  end

  # Converts the object to a solr hash for indexing
  # @param [Hash] solr_doc A hash passable to solr, an empty one is created by default_field_mapper
  #
  def to_solr(solr_doc = {}, *args)
    solr_doc = super(solr_doc)
    Solrizer.insert_field(solr_doc, 'begin_time', begin_time, :sortable)
    Solrizer.insert_field(solr_doc, 'end_time', end_time, :sortable)
    # Clear out incorrectly named dynamic fields
    solr_doc.delete('begin_time_dtsim')
    solr_doc.delete('end_time_dtsim')
    solr_doc
  end

  # A before_save action that sets the times to the start and end of the day in the UTC timezome and formats them as is8061
  def format_times
    self.begin_time = start_of_day(begin_time)
    self.end_time = end_of_day(end_time)
  end

  # A before_save action that sets begin_time to Date.today if a begin_time has not been supplied
  def apply_default_begin_time
    self.begin_time = start_of_day(Date.today) if begin_time.nil?
  end

  # A before_save action that raises an ArgumentError if end_time is not set
  # @raise [ArgumentError] raised if end_time is nil
  def ensure_end_time_present
    fail ArgumentError, 'No end_time supplied' if end_time.nil?
  end

  # A before_save action that ensures begin_time preceeds end_time
  # @raise [ArgumentError] raised if end_time is before or equal to begin_time
  def validate_dates
    apply_default_begin_time
    # We use <= since we have times on our dates, so if they're equal it means a lease with a duration of 0 seconds
    fail ArgumentError, 'end_time predates begin_time' if end_time <= begin_time
  end

  # Take a supplied date and format it in iso8601 with the time portion set to 00:00:00 UTC
  # @param [Date, Time, String] a date or time object or a string that DateTime can parts_with_order
  # @return [String] supplied date and time with the passed date and time portion set to 00:00:00 UTC time in the iso8601 format
  def start_of_day(time)
    DateTime.parse(time.to_s).utc.beginning_of_day.iso8601
  end

  # Take a supplied date and format it in iso8601 with the time portion set to 11:59:59 UTC
  # @param [Date, Time, String] a date or time object or a string that DateTime can parts_with_order
  # @return [String] supplied date and time with the passed date and time portion set to 11:59:59 UTC time in the iso8601 format
  def end_of_day(time)
    DateTime.parse(time.to_s).utc.end_of_day.iso8601
  end

  # Calculate lease type by inspecting read_users and read_groups values, each of which are assumed to contain a single value
  # @return [String] "user" for user lease, "ip" for ip group lease, "local" for local group lease, "external" for external group lease, nil for others
  def lease_type
    return "user" if self.read_users.present?
    group = self.read_groups.first
    return nil if group.nil?
    return "ip" if IPAddr.new(group) rescue false
    return "local" if Admin::Group.exists? group
    return "external"
  end

end
