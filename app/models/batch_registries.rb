# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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

#Handles the registration and replayability of registries
#@since 6.3.0
class BatchRegistries < ActiveRecord::Base
  before_save :check_user
  validates :file_name, :user_id, :collection, presence: true
  has_many :batch_entries, -> { order(position: :asc) }

  # For FactoryGirl's taps, document more TODO
  def file_name=(fn)
    super
    ensure_replay_id
  end

  private
  # Places a value in the replay_id column if there is not one currently
  def ensure_replay_id
    self.replay_name = "#{SecureRandom.uuid}_#{file_name}" if replay_name.nil?
  end

  def check_user
    unless User.exists?(user_id)
      self.error = true
      self.error_message = "No user with id #{user_id} found in system"
    end
  end
end
