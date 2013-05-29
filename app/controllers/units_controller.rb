require "role_controls"
class UnitsController < ApplicationController
  before_filter :authenticate_user!, :set_parent_name!
  load_and_authorize_resource
  respond_to :html
  responders :flash

  def index
    @units = search_sort_paginate(params, Unit.scoped)
  end

  def create
    @unit = Unit.new(params[:unit])
    @unit.created_by_user_id = current_user.user_key
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

    Unit.transaction do 
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
      provider = Avalon::Authentication::Providers.first[:params]
      ldap_client = Avalon::NetID.new provider[:bind_dn], provider[:password], :host => provider[:host]

      manager_uids = params[:managers].split(',')
      manager_uids.delete('multiple')
      manager_uids.map do |uid|

        ldap_user = ldap_client.find_by_net_id( uid )
        raise "Could not find user in LDAP with uid: #{uid}" unless ldap_user
        
        user = User.find_by_uid(uid)
        user ||= User.find_by_email(ldap_user[:email])

        unless user
          user = User.new
        end

        # create or update user information based upon what is in ldap
        user.email = ldap_user[:email]
        user.username = ldap_user[:email]
        user.full_name = ldap_user[:full_name]
        user.uid = ldap_user[:uid]
        user.save!
      
        user
      end
    
    end

end