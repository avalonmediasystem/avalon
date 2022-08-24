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
      @presenter = Samvera::Persona::UsersPresenter.new
      records_total = @presenter.user_count
      @presenter = @presenter.users
      columns = ['username', 'email', 'entry', 'last_sign_in_at', 'invitation_token', 'provider', 'actions']

      # Filtering
      search_value = params['search']['value']
      @presenter = if search_value.present?
                     search_role = @presenter.select { |p| p.groups.any? { |g| g.include? search_value } }
                     search_date = @presenter.select { |p| last_sign_in(p).to_formatted_s(:long_ordinal).include? search_value }
                     search_status = @presenter.select { |p| user_status(p).downcase.include? search_value.downcase }
                     @presenter.where(%(
                                username LIKE :search_value OR
                                email LIKE :search_value OR
                                provider LIKE :search_value
                              ), search_value: "%#{search_value}%")
                               .or(User.where(id: search_role.map(&:id)))
                               .or(User.where(id: search_date.map(&:id)))
                               .or(User.where(id: search_status.map(&:id)))
                   else
                     @presenter
                   end

      # Count
      presenter_filtered_total = @presenter.count

      # Sort
      sort_column = params['order']['0']['column'].to_i rescue 0
      sort_direction = params['order']['0']['dir'] == 'desc' ? 'desc' : 'asc' rescue 'asc'
      session[:presenter_sort] = [sort_column, sort_direction]
      if columns[sort_column] != 'entry'
        @presenter = @presenter.order("lower(#{columns[sort_column].downcase}) #{sort_direction}, #{columns[sort_column].downcase} #{sort_direction}")
        @presenter = @presenter.offset(params['start']).limit(params['length'])
      else
        user_roles = @presenter.collect { |p| [ p.groups, p ] }
        user_roles.sort_by! { |r| [-r[0].length, r] }
        @presenter = user_roles.collect { |p| p[1] }
        @presenter.reverse! if sort_direction == 'desc'
        @presenter = @presenter.slice(params['start'].to_i, params['length'].to_i)
      end

      # Build json response
      response = {
        "draw": params['draw'],
        "recordsTotal": records_total,
        "recordsFiltered": presenter_filtered_total,
        "data": @presenter.collect do |presenter|
          edit_button =
            if presenter.has_attribute?(:provider) && !presenter.provider.nil?
              view_context.tag.span("Edit", class: 'text-muted', title: 'Edit user is unavailable because this user is single sign on', data: { toggle: 'tooltip' })
            else
              view_context.link_to('Edit', main_app.edit_persona_user_path(presenter))
            end
          become_button = view_context.link_to('Become', main_app.impersonate_persona_user_path(presenter), method: :post)
          delete_button = view_context.link_to('Delete', main_app.persona_user_path(presenter), method: :delete, class: 'btn btn-danger btn-sm action-delete', data: { confirm: "Are you sure you wish to delete the user '#{presenter.email}'? This action is irreversible." })
          formatted_roles = format_roles(presenter.groups)
          sign_in = last_sign_in(presenter)
          [
            view_context.link_to(presenter.username, main_app.edit_persona_user_path(presenter)),
            view_context.link_to(presenter.email, main_app.edit_persona_user_path(presenter)),
            view_context.tag.ul(formatted_roles.join, escape: false),
            view_context.tag.relative_time(sign_in.to_formatted_s(:long_ordinal), datetime: sign_in.getutc.iso8601, title: sign_in.to_formatted_s(:standard)),
            user_status(presenter),
            presenter.provider,
            "#{edit_button}&nbsp;|&nbsp;#{become_button}&nbsp;|&nbsp;#{delete_button}"
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
        RoleMap.delete_by(entry: @user.username)
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
      prepend_view_path "#{my_engine_root}/app/views/#{Rails.application.class.module_parent_name.downcase}"
      prepend_view_path Rails.root.join('app', 'views')
    end

    def last_sign_in(user)
      result = user.last_sign_in_at if user.last_sign_in_at?
      result ||= user.invitation_sent_at
      result ||= user.created_at
      result
    end

    def format_roles(roles)
      roles.collect { |r| view_context.tag.li r }
    end

    def user_status(user)
      user.accepted_or_not_invited? ? 'Active' : 'Pending'
    end

    def user_params
      params.require(:user).permit(:email, :username, :password, :password_confirmation, :is_superadmin, :facebook_handle, :twitter_handle, :googleplus_handle, :display_name, :address, :department, :title, :office, :chat_id, :website, :affiliation, :telephone, :avatar, :group_list, :linkedin_handle, :orcid, :arkivo_token, :arkivo_subscription, :zotero_token, :zotero_userid, :preferred_locale, role_ids: [])
    end
  end
end
