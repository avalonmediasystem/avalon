class PlaylistItemsController < ApplicationController
  # TODO: rewrite this to use cancancan's authorize_and_load_resource
  before_action :set_playlist, only: [:create]

  # POST /playlists/1/items
  def create
    annotation = AvalonAnnotation.new(master_file: MasterFile.find(playlist_item_params[:master_file_id]))
    annotation.title = playlist_item_params[:title]
    annotation.comment = playlist_item_params[:comment]
    annotation.start_time = playlist_item_params[:start_time]
    annotation.end_time = playlist_item_params[:end_time]
    annotation.save!
    if PlaylistItem.create(playlist: @playlist, annotation: annotation)
      flash[:success] = "Add to playlist was successful. See it here: #{view_context.link_to("here", playlist_url(@playlist))}"
      render nothing: true, status: 201 and return
    end
    render nothing: true, status: 500 and return
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_playlist
    @playlist = Playlist.find(params[:playlist_id])
  end

  def playlist_item_params
    params.require(:playlist_item).permit(:title, :comment, :master_file_id, :start_time, :end_time)
  end

end
