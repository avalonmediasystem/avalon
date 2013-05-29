
class LdapController < ApplicationController
  before_filter :authenticate_user!
  respond_to :js

  def search
    provider = Avalon::Authentication::Providers.first[:params]
    client = Avalon::NetID.new provider[:bind_dn], provider[:password], :host => provider[:host]
    users = client.autocomplete(params[:q])
    render json: { users: users }
  end

end