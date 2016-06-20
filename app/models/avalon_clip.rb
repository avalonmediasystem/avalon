# An AvalonAnnotation that represents a 'clip', an annotated time-span on a masterfile
# @since 5.0.1
class AvalonClip < AvalonAnnotation

  alias_method :comment, :content
  alias_method :comment=, :content=

  validates :end_time, numericality: { 
    greater_than: Proc.new { |a| Float(a.start_time) rescue 0 }, 
    less_than_or_equal_to: Proc.new { |a| a.max_time }, 
    message: "must be between start time and end of section"
  }

  # Add end time to the solr hash for AvalonMediafragment
  # @return [Hash] a hash capable of submission to solr
  def to_solr
    solr_hash = super
    solr_hash[:end_time_fsi] = end_time
    solr_hash
  end

  # Find the clip's position on a playlist
  # This returns with 1, not 0, as the array start point due to the acts as order gems used on playlist item
  # @param [Int] playlist_id The ID of the playlist
  # @return [Int] the position
  # @return [Nil] if the clip is not on the specified playlist
  def playlist_position(playlist_id)
    p_item = PlaylistItem.where(playlist_id: playlist_id, clip_id: id)[0]
    return p_item if p_item.nil?
    p_item['position']
  end

  # Sets the default selector to a start time of 0 and an end time of the master file length
  def selector_default!
    super
    if self.end_time.nil?
      if master_file.present? && master_file.duration.present?
        self.end_time = master_file.duration
      else
        self.end_time = 1
      end
    end
  end

  def duration
    duration = (end_time-start_time)/1000
    Time.at(duration).utc.strftime(duration<3600?'%M:%S':'%H:%M:%S')
  end

end
