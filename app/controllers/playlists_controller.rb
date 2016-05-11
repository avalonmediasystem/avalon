class PlaylistsController < ApplicationController
  # TODO: rewrite this to use cancancan's authorize_and_load_resource
  before_action :set_playlist, only: [:show, :edit, :update, :destroy]
  before_action :get_all_playlists, only: [:index, :edit]

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
      render action: 'new'
    end
  end

  # PATCH/PUT /playlists/1
  def update
    if @playlist.update(playlist_params)
      redirect_to @playlist, notice: 'Playlist was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /playlists/1
  def destroy
    @playlist.destroy
    redirect_to playlists_url, notice: 'Playlist was successfully destroyed.'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_playlist
    @playlist = Playlist.find(params[:id])
  end

  # Use callbacks to share common setup or constraints between actions.
  def get_all_playlists
    @playlists = Playlist.for_ability(current_ability).to_a
  end

  # Only allow a trusted parameter "white list" through.
  def playlist_params
    params.require(:playlist).permit(:title, :comment, :visibility)
  end
end
