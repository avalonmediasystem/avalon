class PlaylistItemsController < ApplicationController
  # TODO: rewrite this to use cancancan's authorize_and_load_resource
  before_action :set_playlist, only: [:create, :update]

  # POST /playlists/1/items
  def create
    title =  playlist_item_params[:title]
    comment = playlist_item_params[:comment]
    start_time = time_str_to_milliseconds playlist_item_params[:start_time]
    end_time = time_str_to_milliseconds playlist_item_params[:end_time]
    annotation = AvalonAnnotation.new(master_file: MasterFile.find(playlist_item_params[:master_file_id]))
    annotation.title = title
    annotation.comment = comment
    annotation.start_time = start_time
    annotation.end_time = end_time
    unless annotation.valid?
      render json: { message: annotation.errors.full_messages }, status: 400 and return
    end
    unless annotation.save
      render json: { message: "Item was not created: #{annotation.errors.full_messages}" }, status: 500 and return
    end
    if PlaylistItem.create(playlist: @playlist, annotation: annotation)
      render json: { message: "Add to playlist was successful. See it: #{view_context.link_to("here", playlist_url(@playlist))}" }, status: 201 and return
    end
  rescue StandardError => error
    render json: { message: "Item was not created: #{error.message}"}, status: 500 and return
  end

  def update
    playlist_item = PlaylistItem.find(params['id'])
    annotation = AvalonAnnotation.find(playlist_item.annotation.id)
    annotation.title =  params[:title]
    annotation.comment = params[:comment]
    annotation.start_time = time_str_to_milliseconds params[:start_time]
    annotation.end_time = time_str_to_milliseconds params[:end_time]
    if annotation.save
      flash[:success] = "Playlist item details saved successfully."
    else
      flash[:error] = "Playlist item details could not be saved: #{annotation.errors.full_messages}"
    end
    redirect_to edit_playlist_path(@playlist)
  end

  private

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
