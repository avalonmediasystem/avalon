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

class Checkout < ApplicationRecord
  belongs_to :user

  validates :user, :media_object_id, :checkout_time, :return_time, presence: true

  after_initialize :set_checkout_return_times!

  scope :active_for_media_object, ->(media_object_id) { where(media_object_id: media_object_id).where("return_time > now()") }
  scope :active_for_user, ->(user_id) { where(user_id: user_id).where("return_time > now()") }
  scope :returned_for_user, ->(user_id) { where(user_id: user_id).where("return_time < now()") }
  scope :checked_out_to_user, ->(media_object_id, user_id) { where("media_object_id = ? AND user_id = ? AND return_time > now()", media_object_id, user_id) }

  def media_object
    @media_object ||= SpeedyAF::Proxy::MediaObject.find(media_object_id)
    raise ActiveFedora::ObjectNotFoundError if @media_object.nil?
    @media_object
  end

  private

    def set_checkout_return_times!
      self.checkout_time ||= DateTime.current
      self.return_time ||= checkout_time + duration
    end

    def duration
      duration = media_object.lending_period if media_object_id.present?
      duration ||= ActiveSupport::Duration.parse(Settings.controlled_digital_lending.default_lending_period)
      duration
    end
end
