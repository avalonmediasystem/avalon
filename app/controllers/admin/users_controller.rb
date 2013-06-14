class Admin::UsersController < ApplicationController
  before_filter :authenticate_user!
  respond_to :js

  def search
    users = Avalon::UserSearchService.autocomplete(params[:q])
    render json: { users: users }
  end
end
