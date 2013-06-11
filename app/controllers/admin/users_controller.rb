class Admin::UsersController < ApplicationController
  before_filter :authenticate_user!
  respond_to :js

  def search
    user_search = Avalon::UserSearch.new
    users = user_search.autocomplete(params[:q])
    render json: { users: users }
  end
end