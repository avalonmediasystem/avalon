require "role_controls"
class UnitsController < ApplicationController
  before_filter :authenticate_user!, :set_parent_name!
  before_filter 
  load_and_authorize_resource
  respond_to :html
  responders :flash

  def index
    @units = Unit.all
  end

  def create
    @unit = Unit.new(params[:unit])
    @unit.managers =  find_managers!( params )

    if @unit.save
      respond_with @unit do |format|
        format.html { redirect_to [@parent_name, @unit] }
      end
    else
      render 'new'
    end
  end

  def update
    @unit = Unit.find(params[:id])
    @unit.name = params[:unit][:name]
    @unit.managers.clear
    @unit.managers =  find_managers!( params )

    if @unit.valid? && @unit.save!
      respond_with @unit do |format|
        format.html { redirect_to [@parent_name, @unit] }
      end
    else
      render 'edit'
    end

  end

  def destroy
    @unit.destroy
    respond_with @unit do |format|
      format.html { redirect_to [@parent_name, @unit] }
    end
  end

  private

    def set_parent_name!
      @parent_name =  params[:controller].to_s.split('/')[-2..-2].try :first
    end

    def find_managers!(params)
      manager_uids = params[:managers].split(',')
      manager_uids.delete('multiple')
      manager_uids.map do |uid|

        user_from_directory = Avalon::UserSearchService.find_by_uid( uid )
        raise "Could not find user in directory with uid: #{uid}" unless user_from_directory
        
        user = User.find_by_uid(uid) 
        user ||= User.find_by_username(user_from_directory[:username]) if user_from_directory[:username]
        user ||= User.find_by_email(user_from_directory[:email]) if user_from_directory[:email]
        
        if ! user
          user = User.new
          user.guest = true
        p "email #{ user_from_directory.inspect }"
        # create or update user information based upon what is available
        user.email = user_from_directory[:email]
        user.username = user_from_directory[:email] || user_from_directory[:username] #cannot be blank
        user.full_name = user_from_directory[:full_name]
        user.uid = user_from_directory[:uid]
        user.save!
        end


        user
      end
    
    end

end
