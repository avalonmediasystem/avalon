# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

class Admin::UnitsController < ApplicationController
  include NoidValidator
  include Rails::Pagination

  before_action :authenticate_user!
  load_and_authorize_resource except: [:index, :remove, :attach_poster, :remove_poster, :poster]
  before_action :load_and_authorize_units, only: [:index]
  respond_to :html

  def load_and_authorize_units
    authorize!(params[:action].to_sym, Admin::Unit)
    repository = CatalogController.new.blacklight_config.repository
    # Allow the number of units to be greater than 100
    blacklight_config.max_per_page = 100_000
    builder = ::UnitSearchBuilder.new([:add_access_controls_to_solr_params_if_not_admin, :only_wanted_models, :add_paging_to_solr], self).rows(100_000)
    if params[:user].present? && can?(:manage, Admin::Unit)
      user = User.find_by_username_or_email(params[:user])
      if user.blank?
        @units = []
        return
      end
      builder.user = user
    end
    response = repository.search(builder)

    # Query solr for facet values for unit media object counts and pass into presenter to avoid making 2 solr queries per unit
    count_query = 'has_model_ssim:"Admin::Collection"'
    count_response = ActiveFedora::SolrService.get(count_query, { rows: 0, facet: true, 'facet.field': "heldBy_ssim", 'facet.limit': -1 })
    counts_array = count_response["facet_counts"]["facet_fields"]["heldBy_ssim"] rescue []
    counts = counts_array.each_slice(2).to_h

    @units = response.documents.collect { |doc| ::Admin::UnitPresenter.new(doc, collection_count: counts[doc.id] || 0) }
    @units = @units.sort_by { |u| u.name.downcase }
  end

  # GET /units
  def index
    respond_to do |format|
      format.html
      format.json { paginate json: @units }
    end
  end

  # GET /units/1
  def show
    respond_to do |format|
      format.json { render json: @unit.to_json }
      format.html {
        @groups = @unit.default_local_read_groups
        @users = @unit.default_read_users
        @virtual_groups = @unit.default_virtual_read_groups
        @ip_groups = @unit.default_ip_read_groups
        @visibility = @unit.default_visibility

        @addable_groups = Admin::Group.non_system_groups.reject { |g| @groups.include? g.name }
        @addable_courses = Course.all.reject { |c| @virtual_groups.include? c.context_id }
      }
    end
  end

  # GET /units/new
  def new
    respond_to do |format|
      format.js   { render json: modal_form_response(@unit) }
      format.html { render 'new' }
    end
  end

  # GET /units/1/edit
  def edit
    respond_to do |format|
      format.js   { render json: modal_form_response(@unit) }
    end
  end

  # GET /units/1/items
  def items
    collections = paginate @unit.collections
    render json: collections.to_a.collect { |c| [c.id, c.as_json] }.to_h
  end

  # POST /units
  def create
    @unit = Admin::Unit.create(unit_params.merge(managers: [current_user.user_key]))
    if @unit.persisted?
      User.where(Devise.authentication_keys.first => [Avalon::RoleControls.users('administrator')].flatten).each do |admin_user|
        NotificationsMailer.new_unit(
          creator_id: current_user.id,
          unit_id: @unit.id,
          user_id: admin_user.id,
          subject: "New unit: #{@unit.name}"
        ).deliver_later
      end
      respond_to do |format|
        format.html do
          redirect_to @unit, notice: 'unit was successfully created.'
        end
        format.json do
          render json: {id: @unit.id}, status: 200
        end
      end
    else
      logger.warn "Failed to create unit #{@unit.name rescue '<unknown>'}: #{@unit.errors.full_messages}"
      respond_to do |format|
        format.html do
          flash.now[:error] = @unit.errors.full_messages.to_sentence
          render action: 'new'
        end
        format.json do
          render json: { errors: ['Failed to create unit:']+@unit.errors.full_messages}, status: 422
        end
      end
    end
  end

  # PUT /units/1
  def update
    name_changed = false
    if params[:admin_unit].present?
      if params[:admin_unit][:name].present?
        if params[:admin_unit][:name] != @unit.name && can?('update_name', @unit)
          @old_name = @unit.name
          @unit.name = params[:admin_unit][:name]
          name_changed = true
        end
      end
    end
    ["manager", "editor"].each do |title|
      if params["submit_add_#{title}"].present?
        if params["add_#{title}"].present? && can?("update_#{title.pluralize}".to_sym, @unit)
          begin
            @unit.send "add_#{title}".to_sym, params["add_#{title}"].strip
          rescue ArgumentError => e
            flash[:error] = e.message
          end
        else
          flash[:error] = "#{title.titleize} can't be blank."
        end
      end

      remove_access = "remove_#{title}"
      if params[remove_access].present? && can?("update_#{title.pluralize}".to_sym, @unit)
        begin
          @unit.send remove_access.to_sym, params[remove_access]
        rescue ArgumentError => e
          flash[:error] = e.message
        end
      end
    end

    update_access(@unit, params) if can?(:update_access_control, @unit)

    @unit.update_attributes unit_params if unit_params.present?
    saved = @unit.save
    if saved
      if name_changed
        User.where(Devise.authentication_keys.first => [Avalon::RoleControls.users('administrator')].flatten).each do |admin_user|
          NotificationsMailer.update_unit(
            updater_id: current_user.id,
            unit_id: @unit.id,
            user_id: admin_user.id,
            old_name: @old_name,
            subject: "Notification: unit #{@old_name} changed to #{@unit.name}"
          ).deliver_later
        end
      end

      apply_access(@unit, params) if can?(:update_access_control, @unit)
    end

    respond_to do |format|
      format.html do
        flash[:notice] = Array(flash[:notice]) + @unit.errors.full_messages unless @unit.valid?
        redirect_to @unit
      end
      format.json do
        if saved
          render json: {id: @unit.id}, status: 200
        else
          logger.warn "Failed to update unit #{@unit.name rescue '<unknown>'}: #{@unit.errors.full_messages}"
          render json: {errors: ['Failed to update unit:']+@unit.errors.full_messages}, status: 422
        end
      end
    end
  end

  # GET /units/1/remove
  def remove
    @unit = Admin::Unit.find(params['id'])
    authorize! :destroy, @unit
    @objects    = @unit.collections
  end

  # DELETE /units/1
  def destroy
    @source_unit = @unit
    target_path = admin_units_path
    if @source_unit.collections.count > 0
      if @source_unit.collections.all?(&:valid?)
        @target_unit = Admin::Unit.find(params[:target_unit_id])
        Admin::Unit.reassign_collections( @source_unit.collections, @source_unit, @target_unit )
        target_path = admin_unit_path(@target_unit)
        @source_unit.reload
      else
        flash[:error] = "Unit contains invalid collections that cannot be moved. Please address these issues before attempting to delete #{@source_unit.name}."
        redirect_to admin_unit_path(@source_unit) and return
      end
    end
    if @source_unit.collections.count == 0
      @source_unit.destroy
      redirect_to target_path
    else
      flash[:error] = "Something went wrong. #{@source_unit.name} is not empty."
      redirect_to admin_unit_path(@source_unit)
    end
  end

  def attach_poster
    @unit = Admin::Unit.find(params['id'])
    authorize! :edit, @unit, message: "You do not have sufficient privileges to add a poster image."

    poster_file = params[:admin_unit][:poster]
    is_image = check_image_compliance(poster_file&.path)
    if is_image
      @unit.poster.content = poster_file.read
      @unit.poster.mime_type = 'image/png'
      @unit.poster.original_name = poster_file.original_filename

      if @unit.save
        flash[:success] = "Poster file successfully added."
      else
        flash[:error] = "There was a problem storing the poster image."
      end
    else
      flash[:error] = "Uploaded file is not a recognized poster image file"
    end

    redirect_to admin_unit_path(@unit)
  end

  def remove_poster
    @unit = Admin::Unit.find(params['id'])
    authorize! :edit, @unit, message: "You do not have sufficient privileges to remove a poster image."

    @unit.poster.content = ''
    @unit.poster.original_name = ''

    if @unit.save
      flash[:success] = "Poster file successfully removed."
    else
      flash[:error] = "There was a problem removing the poster image."
    end

    redirect_to admin_unit_path(@unit)
  end

  def poster
    @unit = SpeedyAF::Proxy::Admin::Unit.find(params['id'])
    authorize! :show, @unit

    file = @unit.poster
    if file.nil? || file.empty?
      render plain: 'Unit Poster Not Found', status: :not_found
    else
      render plain: file.content, content_type: file.mime_type
    end
  end

  rescue_from Avalon::VocabularyNotFound do |exception|
    support_email = Settings.email.support
    notice_text = I18n.t('errors.controlled_vocabulary_error') % [exception.message, support_email, support_email]
    redirect_to root_path, flash: { error: notice_text.html_safe }
  end

  private

  def update_access(unit, params)
    # If Save Access Setting button or Add/Remove User/Group button has been clicked
    ["group", "class", "user", "ipaddress"].each do |title|
      if params["submit_add_#{title}"].present?
        if params["add_#{title}"].present?
          val = params["add_#{title}"].strip
          if title=='user'
            unit.default_read_users += [val]
          elsif title=='ipaddress'
            if ( IPAddr.new(val) rescue false )
              unit.default_read_groups += [val]
            else
              flash[:notice] = "IP Address #{val} is invalid. Valid examples: 124.124.10.10, 124.124.0.0/16, 124.124.0.0/255.255.0.0"
            end
          else
            unit.default_read_groups += [val]
          end
        else
          flash[:notice] = "#{title.titleize} can't be blank."
        end
      end

      if params["remove_#{title}"].present?
        if ["group", "class", "ipaddress"].include? title
          # This is a hack to deal with the fact that calling default_read_groups#delete isn't marking the record as dirty
          # TODO: Ensure default_read_groups is tracked by ActiveModel::Dirty
          unit.default_read_groups_will_change!
          unit.default_read_groups.delete params["remove_#{title}"]
        else
          # This is a hack to deal with the fact that calling default_read_users#delete isn't marking the record as dirty
          # TODO: Ensure default_read_users is tracked by ActiveModel::Dirty
          unit.default_read_users_will_change!
          unit.default_read_users.delete params["remove_#{title}"]
        end
      end
    end

    update_access_settings(unit, params)
  end

  def update_access_settings(unit, params)
    if params[:save_field] == "visibility"
      unit.default_visibility = params[:visibility] unless params[:visibility].blank?
    end
    if params[:save_field] == "discovery"
      unit.default_hidden = params[:hidden] == "1"
    end
  end

  def apply_access(unit, params)
    BulkActionJobs::ApplyUnitAccessControl.perform_later(unit.id, params[:overwrite] == "true", params[:save_field]) if params["apply_to_existing"].present?
  end

  def unit_params
    params.permit(:admin_unit => [:name, :description, :contact_email, :website_label, :website_url, :managers => []])[:admin_unit]
  end

  def check_image_compliance(poster_path)
    fastimage = FastImage.new(poster_path)
    # Size derived from width and aspect ratio from JS code, assets/javascript/crop_upload.js:60-63
    fastimage.type == :png && fastimage.size == [700, 560] # [width, height]
  end
end
