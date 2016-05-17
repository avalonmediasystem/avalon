class PlaylistItemsController < ApplicationController
  # TODO: rewrite this to use cancancan's authorize_and_load_resource
  before_action :set_playlist, only: [:create]

  # POST /playlists/1/items
  def create
    title =  playlist_item_params[:title]
    comment = playlist_item_params[:comment]
    start_time = time_str_to_milliseconds playlist_item_params[:start_time]
    end_time = time_str_to_milliseconds playlist_item_params[:end_time]
    messages = []
    messages << 'Title is required.' if title.blank?
    messages << "Specified start time not valid." unless numeric?(start_time)
    messages << "Specified end time not valid." unless numeric?(end_time)
    unless messages.empty?
      render json: { message: messages.join(' ') }, status: 400 and return
    end
    annotation = AvalonAnnotation.new(master_file: MasterFile.find(playlist_item_params[:master_file_id]))
    annotation.title = title
    annotation.comment = comment
    annotation.start_time = start_time
    annotation.end_time = end_time
    unless annotation.save!
      render json: { message: "Item was not created: #{annotation.errors.full_messages}" }, status: 500 and return
    end
    if PlaylistItem.create(playlist: @playlist, annotation: annotation)
      render json: { message: "Add to playlist was successful. See it: #{view_context.link_to("here", playlist_url(@playlist))}" }, status: 201 and return
    end
    render nothing: true, status: 500 and return
  end

  private

  def numeric? n
    Float(n) != nil rescue false
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_playlist
    @playlist = Playlist.find(params[:playlist_id])
  end

  def playlist_item_params
    params.require(:playlist_item).permit(:title, :comment, :master_file_id, :start_time, :end_time)
  end

  def time_str_to_milliseconds value
    if value.is_a?(Numeric)
      value.floor
    elsif value.is_a?(String)
      result = 0
      segments = value.split(/:/).reverse
      begin
        segments.each_with_index { |v,i| result += i > 0 ? Float(v) * (60**i) * 1000 : (Float(v) * 1000) }
        result.to_i
      rescue
        return value
      end
    else
      value
    end    
  end
  
end
