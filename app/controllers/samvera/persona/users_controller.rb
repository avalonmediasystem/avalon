# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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
# Added LDAP group recalculation in impersonate and stop_impersonating
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
      if defined?(add_breadcrumb)
        add_breadcrumb t(:'hyrax.controls.home'), main_app.root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'samvera.persona.users.index.title'), main_app.persona_users_path
      end

      @presenter = Samvera::Persona::UsersPresenter.new
      records_total = @presenter.user_count
      columns = ['username', 'email', 'groups', 'last_sign_in_at', 'accepted_or_not_invited', 'provider', 'actions']

      # TODO: Filter username, email, groups, status, provider
      # # Filter username
      # username_filter = params['search']['value']
      # @presenter = @presenter.username_like(username_filter) if username_filter.present?
      #
      # # Filter email
      # email_filter = params['columns']['1']['search']['value']
      # @presenter = @presenter.email_like(email_filter) if email_filter.present?
      #
      # # Filter groups
      # group_filter = params['columns']['2']['search']['value']
      # @presenter = @presenter.group_like(group_filter) if group_filter.present?
      #
      # # Filter status
      # status_filter = params['columns']['4']['search']['value']
      # @presenter = @presenter.status_like(status_filter) if status_filter.present?
      #
      # # Filter provider
      # provider_filter = params['columns']['5']['search']['value']
      # @presenter = @presenter.provider_like(provider_filter) if provider_filter.present?
      #
      # # TODO: Sort
      # sort_column = params['order']['0']['column'].to_i rescue 0
      # sort_direction = params['order']['0']['dir'] rescue 'asc'
      # session[:presenter_sort] = [sort_column, sort_direction]
      # @presenter = @presenter.order(columns[sort_column].downcase => sort_direction)
      # @presenter = @presenter.offset(params['start']).limit(params['length'])
      #
      # # TODO: Count
      # presenter_filtered_total = @presenter.count

      # TODO: Build json response with actions and other values
      response = {
        "draw": params['draw'],
        "recordsTotal": records_total,
        # "recordsFiltered": presenter_filtered_total,
        "data": @presenter.users.each do |user|
          require pry, binding.pry
          edit_button = view_context.link_to(main_app.edit_persona_user_path(user), class: 'btn btn-default btn-xs') do
            "<i class='fa fa-edit' aria-hidden='true'></i> Edit".html_safe
          end
          become_button = view_context.link_to(main_app.impersonate_persona_user_path(user.id), method: :post, class: 'btn btn-xs btn-confirmation') do
            "<i class='fa fa-become' aria-hidden='true'></i> Become".html_safe
          end
          delete_button = view_context.link_to(main_app.persona_user_path(user), method: :delete, class: 'btn btn-xs btn-danger action-delete', data: { confirm: t('.destroy.confirmation', user:user.email)}) do
            "<i class='fa fa-times' aria-hidden='true'></i> Delete".html_safe
          end
          if user.has_attribute?(:provider)
            user_provider = user.provider
          end
          [
            view_context.link_to(user.username, main_app.edit_persona_user_path(user)),
            view_context.link_to(user.email, main_app.edit_persona_user_path(user)),
            # Placeholder for roles
            "<td data-order=#{@presenter.last_accessed(user).getutc.iso8601}><relative-time datetime='#{@presenter.last_accessed(user).to_formatted_s(:standard)}'>#{@presenter.last_accessed(user).to_formatted_s(:long_ordinal)}</relative-time></td>",
            "<td>#{user.accepted_or_not_invited? ? t('.status.active') : t('.status.pending')}</td>",
            "<td>#{user_provider}</td>",
            "#{edit_button} #{become_button} #{delete_button}"
          ]
        end
      }

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
      # Recalculate user_session[:virtual_groups]
      user_session[:virtual_groups] = current_user.ldap_groups
      redirect_to main_app.root_path
    end

    def stop_impersonating
      stop_impersonating_user
      # Recalculate user_session[:virtual_groups]
      user_session[:virtual_groups] = current_user.ldap_groups
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
      new_params = params.require(:user).permit(:email, :username, :password, :password_confirmation, :is_superadmin, :facebook_handle, :twitter_handle, :googleplus_handle, :display_name, :address, :department, :title, :office, :chat_id, :website, :affiliation, :telephone, :avatar, :group_list, :linkedin_handle, :orcid, :arkivo_token, :arkivo_subscription, :zotero_token, :zotero_userid, :preferred_locale, role_ids: [])
      new_params[:tags] = JSON.parse(new_params[:tags]) if new_params[:tags].present?
      new_params
    end
  end
end
