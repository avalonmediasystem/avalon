# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

# Copied here in full from samvera-persona 0.1.7
# Added prepend_view_path
# TODO: Determine why this is necessary and remove this override
module Samvera
  class Persona::UsersController < ApplicationController
    # include Hyrax based theme and admin only connection
    begin
      if defined?(Avalon)
        include Samvera::Persona::AvalonAuth
      end
      include Hyrax::Admin::UsersControllerBehavior
    rescue NameError
      before_action :authenticate_user!
    end

    before_action :load_user, only: [:edit, :update, :destroy]
    before_action :app_view_path
    # NOTE: User creation/invitations handled by devise_invitable
    def index
      # Hyrax derivitives have breadcrumbs, Avalon does not
      if defined?(add_breadcrumb)
        add_breadcrumb t(:'hyrax.controls.home'), main_app.root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'samvera.persona.users.index.title'), main_app.persona_users_path
      end

      @presenter = Samvera::Persona::UsersPresenter.new
    end

    # POST /persona/users/paged_index
    def paged_index
      # Timelines for index page are loaded dynamically by jquery datatables javascript which
      # requests the html for only a limited set of rows at a time.
      @presenter = Samvera::Persona::UsersPresenter.new
      records_total = @presenter.user_count
      columns = ['username', 'email', 'groups', 'last_sign_in_at', 'accepted_or_not_invited', 'provider', 'actions']

      # TODO: Filter username, email, groups, status, provider
      # TODO: Sort
      # TODO: Count
      # TODO: Build json response with actions and other values
      
      respond_to do |format|
        format.json do
          render json: response
        end
      end
    end

    # GET /persona/users/1/edit
    def edit
      # Hyrax derivitives have breadcrumbs, Avalon does not
      if defined?(add_breadcrumb)
        add_breadcrumb t(:'hyrax.controls.home'), main_app.root_path
        add_breadcrumb t(:'hyrax.admin.sidebar.users'), main_app.persona_users_path
        add_breadcrumb @user.display_name, main_app.edit_persona_user_path(@user)
      end
    end

    # PATCH/PUT persona/users/1
    # PATCH/PUT persona/users/1.json
    def update
      # required for settings form to submit when password is left blank
      if params[:user][:password].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end

      respond_to do |format|
        if @user.update_attributes(user_params)
          @user.save

          format.html { redirect_to main_app.persona_users_path, notice: 'User was successfully updated.' }#move to locales
          format.json { render :show, status: :ok }
        else
          format.html { render :edit }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end

    # Become a user
    def impersonate
      user = User.find(params[:id])
      impersonate_user(user)
      redirect_to main_app.root_path
    end

    def stop_impersonating
      stop_impersonating_user
      redirect_to main_app.persona_users_path, notice: t('.become.over')
    end

    # Delete a user from the site
    def destroy
      #TODO update hyku user.destroy to do roles.destroy_all instead
      if @user.present? && @user.destroy
        redirect_to main_app.persona_users_path, notice: t('.success', user: @user)
      else
        redirect_to main_app.persona_users_path flash: { error: t('.failure', user: @user) }
      end
    end

    private

    def load_user
      if User.respond_to?(:from_url_component)
        @user = User.from_url_component(params[:id])
      else
        @user = User.find(params[:id])
      end
    end

    def app_view_path
      my_engine_root = Samvera::Persona::Engine.root.to_s
      prepend_view_path "#{my_engine_root}/app/views/#{Rails.application.class.parent_name.downcase}"
      prepend_view_path Rails.root.join('app', 'views')
    end

    def user_params
      params.require(:user).permit(:email, :username, :password, :password_confirmation, :is_superadmin, :facebook_handle, :twitter_handle, :googleplus_handle, :display_name, :address, :department, :title, :office, :chat_id, :website, :affiliation, :telephone, :avatar, :group_list, :linkedin_handle, :orcid, :arkivo_token, :arkivo_subscription, :zotero_token, :zotero_userid, :preferred_locale, role_ids: [])
    end
  end
end
