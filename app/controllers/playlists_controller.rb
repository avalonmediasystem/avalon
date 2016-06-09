class PlaylistsController < ApplicationController
  # TODO: rewrite this to use cancancan's authorize_and_load_resource
  before_action :authenticate_user!, except: [:show]
  load_and_authorize_resource

  before_action :get_all_playlists, only: [:index, :edit, :update]

  # GET /playlists
  def index
  end

  # GET /playlists/1
  def show
  end

  # GET /playlists/new
  def new
    @playlist = Playlist.new
  end

  # GET /playlists/1/edit
  def edit
    # We are already editing our playlist, we don't need it to show up in this array as well
    @playlists.delete( @playlist )
  end

  # POST /playlists
  def create
    @playlist = Playlist.new(playlist_params.merge(user: current_user))
    if @playlist.save
      redirect_to @playlist, notice: 'Playlist was successfully created.'
    else
      flash.now[:error] = @playlist.errors.full_messages.to_sentence
      render action: 'new'
    end
  end

  # PATCH/PUT /playlists/1
  def update
    if update_playlist(@playlist)
      respond_to do |format|
        format.html do
          redirect_to edit_playlist_path(@playlist), notice: 'Playlist was successfully updated.'
        end
        format.json do
          render json: @playlist
        end
      end
    else
      flash.now[:error] = "There are errors with your submission.  #{@playlist.errors.full_messages.join(', ')}"
      render action: 'edit'
    end
  end

  def update_multiple
    if request.request_method=='DELETE'
      PlaylistItem.where(id: params[:annotation_ids]).to_a.map(&:destroy)
    elsif params[:new_playlist_id].present? and params[:annotation_ids]
      @new_playlist = Playlist.find(params[:new_playlist_id])
      pis = PlaylistItem.where(id: params[:annotation_ids])
      @new_playlist.items += pis
      @playlist.items -= pis
      @new_playlist.save!
      @playlist.save!
    end
    redirect_to edit_playlist_path(@playlist), notice: 'Playlist was successfully updated.'
  end

  # DELETE /playlists/1
  def destroy
    @playlist.destroy
    redirect_to playlists_url, notice: 'Playlist was successfully destroyed.'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def get_all_playlists
    @playlists = Playlist.for_ability(current_ability).to_a
  end

  # Only allow a trusted parameter "white list" through.
  def playlist_params
    params.require(:playlist).permit(:title, :comment, :visibility, :annotation_ids, items_attributes: [:id, :position])
  end

  def update_playlist(playlist)
    playlist.assign_attributes(playlist_params)
    reorder_items(playlist)
    playlist.save
  end

  # This updates the positions of the playlist items
  def reorder_items(playlist)
    # we have to do a sort_by, not order, because the updated attributes have not been saved.
    changed_playlist, new, changed_position, unchanged = playlist.items.
      sort_by(&:position).
      group_by do |item|
	if item.playlist_id_was != item.playlist_id
	  :changed_playlist
	elsif item.position_was.nil?
	  :new
	elsif item.position_was != item.position
	  :changed_position
	else
	  :unchanged
	end
    end.values_at(:changed_playlist, :new, :changed_position, :unchanged).map(&:to_a)
    # items that will be in this playlist
    unmoved_items = unchanged
    # place items whose positions were specified
    changed_position.map {|item| unmoved_items.insert(item.position - 1, item)}
    # add new items at the end
    unmoved_items = unmoved_items + new
    # calculate positions
    unmoved_items.compact.
      select {|item| item.playlist_id_was == item.playlist_id}.
      each_with_index do |item, position|
	item.position = position + 1
      end

    # items that have moved to another playlist
    changed_playlist.select {|item| item.playlist_id_was != item.playlist_id}.each do |item|
      item.position = nil
    end
  end
end
