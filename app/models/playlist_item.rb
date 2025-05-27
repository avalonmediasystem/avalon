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

require 'acts_as_list'

class PlaylistItem < ActiveRecord::Base
  belongs_to :playlist, touch: true
  validates :playlist, presence: true
  acts_as_list scope: :playlist

  belongs_to :clip, class_name: 'AvalonClip', dependent: :destroy
  has_many :marker, class_name: 'AvalonMarker', dependent: :destroy
  validates :clip, presence: true
  delegate :title, :comment, :start_time, :end_time, :title=, :comment=, :start_time=, :end_time=, :master_file, to: :clip
  before_save do
    clip.save
  end

  def duplicate!
    return nil if clip.master_file.nil?
    new_clip = clip.dup
    new_clip.save!

    new_playlist_item = PlaylistItem.create(playlist: playlist, clip: new_clip)

    marker.each do |old_marker|
      new_marker = old_marker.dup
      new_marker.save!
      new_playlist_item.marker << new_marker
    end
    new_playlist_item.save!
    new_playlist_item
  end
end
