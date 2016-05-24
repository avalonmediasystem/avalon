require 'acts_as_list'

class PlaylistItem < ActiveRecord::Base
#  after_save :recount_folders
  belongs_to :playlist, touch: true
  validates :playlist, presence: true
  acts_as_list scope: :playlist

  belongs_to :annotation, class_name: AvalonAnnotation, dependent: :destroy
  validates :annotation, presence: true
  delegate :title, :comment, :start_time, :end_time, :title=, :comment=, :start_time=, :end_time=, :master_file, to: :annotation
  before_save do
    annotation.save
  end
end
