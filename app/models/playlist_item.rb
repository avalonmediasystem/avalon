require 'acts_as_list'

class PlaylistItem < ActiveRecord::Base
#  after_save :recount_folders
  belongs_to :playlist, touch: true
  validates :playlist, presence: true
  acts_as_list scope: :playlist

  belongs_to :annotation, class_name: AvalonAnnotation, dependent: :destroy
  validates :annotation, presence: true

#  def recount_folders
#    Array(changes['folder_id']).compact.each do |folder_id|
#      f = Folder.find(folder_id)
#      f.recalculate_size
#      f.save!
#    end
#  end
end
