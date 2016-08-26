require 'acts_as_list'

class PlaylistItem < ActiveRecord::Base
  belongs_to :playlist, touch: true
  validates :playlist, presence: true
  acts_as_list scope: :playlist

  belongs_to :clip, class_name: AvalonClip, dependent: :destroy
  has_many :marker, class_name: AvalonMarker, dependent: :destroy
  validates :clip, presence: true
  delegate :title, :comment, :start_time, :end_time, :title=, :comment=, :start_time=, :end_time=, :master_file, to: :clip
  before_save do
    clip.save
  end
end
