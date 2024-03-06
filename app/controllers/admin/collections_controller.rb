# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

class Admin::CollectionsController < ApplicationController
  include NoidValidator
  include Rails::Pagination

  before_action :authenticate_user!
  load_and_authorize_resource except: [:index, :remove, :attach_poster, :remove_poster, :poster]
  before_action :load_and_authorize_collections, only: [:index]
  respond_to :html

  def load_and_authorize_collections
    authorize!(params[:action].to_sym, Admin::Collection)
    repository = CatalogController.new.blacklight_config.repository
    # Allow the number of collections to be greater than 100
    blacklight_config.max_per_page = 100_000
    builder = ::CollectionSearchBuilder.new([:add_access_controls_to_solr_params_if_not_admin, :only_wanted_models, :add_paging_to_solr], self).rows(100_000)
    if params[:user].present? && can?(:manage, Admin::Collection)
      user = User.find_by_username_or_email(params[:user])
      unless user.present?
        @collections = []
        return
      end
      builder.user = user
    end
    response = repository.search(builder)

    # Query solr for facet values for collection media object counts and pass into presenter to avoid making 2 solr queries per collection
    count_query = "has_model_ssim:MediaObject"
    count_response = ActiveFedora::SolrService.get(count_query, { rows: 0, facet: true, 'facet.field': "isMemberOfCollection_ssim", 'facet.limit': -1 })
    counts_array = count_response["facet_counts"]["facet_fields"]["isMemberOfCollection_ssim"] rescue []
    counts = counts_array.each_slice(2).to_h
    unpublished_query = count_query + " AND workflow_published_sim:Unpublished"
    unpublished_count_response = ActiveFedora::SolrService.get(unpublished_query, { rows: 0, facet: true, 'facet.field': "isMemberOfCollection_ssim", 'facet.limit': -1 })
    unpublished_counts_array = unpublished_count_response["facet_counts"]["facet_fields"]["isMemberOfCollection_ssim"] rescue []
    unpublished_counts = unpublished_counts_array.each_slice(2).to_h

    @collections = response.documents.collect do |doc| 
                     ::Admin::CollectionPresenter.new(doc, 
                                                      media_object_count: (counts[doc.id] || 0),
                                                      unpublished_media_object_count: (unpublished_counts[doc.id] || 0))
                   end.sort_by { |c| c.name.downcase }
  end

  # GET /collections
  def index
    respond_to do |format|
      format.html
      format.json { paginate json: @collections }
    end
  end

  # GET /collections/1
  def show
    respond_to do |format|
      format.json { render json: @collection.to_json }
      format.html {
        @groups = @collection.default_local_read_groups
        @users = @collection.default_read_users
        @virtual_groups = @collection.default_virtual_read_groups
        @ip_groups = @collection.default_ip_read_groups
        @visibility = @collection.default_visibility
        @default_lending_period = @collection.default_lending_period

        @addable_groups = Admin::Group.non_system_groups.reject { |g| @groups.include? g.name }
        @addable_courses = Course.all.reject { |c| @virtual_groups.include? c.context_id }
      }
    end
  end

  # GET /collections/new
  def new
    respond_to do |format|
      format.js   { render json: modal_form_response(@collection) }
      format.html { render 'new' }
    end
  end

  # GET /collections/1/edit
  def edit
    respond_to do |format|
      format.js   { render json: modal_form_response(@collection) }
    end
  end

  # GET /collections/1/items
  def items
    mos = paginate @collection.media_objects
    render json: mos.to_a.collect { |mo| [mo.id, mo.as_json(include_structure: params[:include_structure] == "true")] }.to_h
  end

  # POST /collections
  def create
    @collection = Admin::Collection.create(collection_params.merge(managers: [current_user.user_key]))
    if @collection.persisted?
      User.where(Devise.authentication_keys.first => [Avalon::RoleControls.users('administrator')].flatten).each do |admin_user|
        NotificationsMailer.new_collection(
          creator_id: current_user.id,
          collection_id: @collection.id,
          user_id: admin_user.id,
          subject: "New collection: #{@collection.name}"
        ).deliver_later
      end
      respond_to do |format|
        format.html do
          redirect_to @collection, notice: 'Collection was successfully created.'
        end
        format.json do
          render json: {id: @collection.id}, status: 200
        end
      end
    else
      logger.warn "Failed to create collection #{@collection.name rescue '<unknown>'}: #{@collection.errors.full_messages}"
      respond_to do |format|
        format.html do
          flash.now[:error] = @collection.errors.full_messages.to_sentence
          render action: 'new'
        end
        format.json do
          render json: { errors: ['Failed to create collection:']+@collection.errors.full_messages}, status: 422
        end
      end
    end
  end

  # PUT /collections/1
  def update
    name_changed = false
    if params[:admin_collection].present?
      if params[:admin_collection][:name].present?
        if params[:admin_collection][:name] != @collection.name && can?('update_name', @collection)
          @old_name = @collection.name
          @collection.name = params[:admin_collection][:name]
          name_changed = true
        end
      end
    end
    ["manager", "editor", "depositor"].each do |title|
      if params["submit_add_#{title}"].present?
        if params["add_#{title}"].present? && can?("update_#{title.pluralize}".to_sym, @collection)
          begin
            @collection.send "add_#{title}".to_sym, params["add_#{title}"].strip
          rescue ArgumentError => e
            flash[:error] = e.message
          end
        else
          flash[:error] = "#{title.titleize} can't be blank."
        end
      end

      remove_access = "remove_#{title}"
      if params[remove_access].present? && can?("update_#{title.pluralize}".to_sym, @collection)
        begin
          @collection.send remove_access.to_sym, params[remove_access]
        rescue ArgumentError => e
          flash[:error] = e.message
        end
      end
    end

    update_access(@collection, params) if can?(:update_access_control, @collection)

    @collection.update_attributes collection_params if collection_params.present?
    saved = @collection.save
    if saved
      if name_changed
        User.where(Devise.authentication_keys.first => [Avalon::RoleControls.users('administrator')].flatten).each do |admin_user|
          NotificationsMailer.update_collection(
            updater_id: current_user.id,
            collection_id: @collection.id,
            user_id: admin_user.id,
            old_name: @old_name,
            subject: "Notification: collection #{@old_name} changed to #{@collection.name}"
          ).deliver_later
        end
      end

      apply_access(@collection, params) if can?(:update_access_control, @collection)
    end

    respond_to do |format|
      format.html do
        flash[:notice] = Array(flash[:notice]) + @collection.errors.full_messages unless @collection.valid?
        redirect_to @collection
      end
      format.json do
        if saved
          render json: {id: @collection.id}, status: 200
        else
          logger.warn "Failed to update collection #{@collection.name rescue '<unknown>'}: #{@collection.errors.full_messages}"
          render json: {errors: ['Failed to update collection:']+@collection.errors.full_messages}, status: 422
        end
      end
    end
  end

  # GET /collections/1/remove
  def remove
    @collection = Admin::Collection.find(params['id'])
    authorize! :destroy, @collection
    @objects    = @collection.media_objects
    @candidates = get_user_collections.reject { |c| c == @collection }
  end

  # DELETE /collections/1
  def destroy
    @source_collection = @collection
    target_path = admin_collections_path
    if @source_collection.media_objects.count > 0
      if @source_collection.media_objects.all?(&:valid?)
        @target_collection = Admin::Collection.find(params[:target_collection_id])
        Admin::Collection.reassign_media_objects( @source_collection.media_objects, @source_collection, @target_collection )
        target_path = admin_collection_path(@target_collection)
        @source_collection.reload
      else
        flash[:error] = "Collection contains invalid media objects that cannot be moved. Please address these issues before attempting to delete #{@source_collection.name}."
        redirect_to admin_collection_path(@source_collection) and return
      end
    end
    if @source_collection.media_objects.count == 0
      @source_collection.destroy
      redirect_to target_path
    else
      flash[:error] = "Something went wrong. #{@source_collection.name} is not empty."
      redirect_to admin_collection_path(@source_collection)
    end
  end

  def attach_poster
    @collection = Admin::Collection.find(params['id'])
    authorize! :edit, @collection, message: "You do not have sufficient privileges to add a poster image."

    poster_file = params[:admin_collection][:poster]
    is_image = check_image_compliance(poster_file&.path)
    if is_image
      @collection.poster.content = poster_file.read
      @collection.poster.mime_type = 'image/png'
      @collection.poster.original_name = poster_file.original_filename

      if @collection.save
        flash[:success] = "Poster file successfully added."
      else
        flash[:error] = "There was a problem storing the poster image."
      end
    else
      flash[:error] = "Uploaded file is not a recognized poster image file"
    end

    redirect_to admin_collection_path(@collection)
  end

  def remove_poster
    @collection = Admin::Collection.find(params['id'])
    authorize! :edit, @collection, message: "You do not have sufficient privileges to remove a poster image."

    @collection.poster.content = ''
    @collection.poster.original_name = ''

    if @collection.save
      flash[:success] = "Poster file successfully removed."
    else
      flash[:error] = "There was a problem removing the poster image."
    end

    redirect_to admin_collection_path(@collection)
  end

  def poster
    @collection = SpeedyAF::Proxy::Admin::Collection.find(params['id'])
    authorize! :show, @collection

    file = @collection.poster
    if file.nil? || file.empty?
      render plain: 'Collection Poster Not Found', status: :not_found
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

  def update_access(collection, params)
    # If Save Access Setting button or Add/Remove User/Group button has been clicked
    ["group", "class", "user", "ipaddress"].each do |title|
      if params["submit_add_#{title}"].present?
        if params["add_#{title}"].present?
          val = params["add_#{title}"].strip
          if title=='user'
            collection.default_read_users += [val]
          elsif title=='ipaddress'
            if ( IPAddr.new(val) rescue false )
              collection.default_read_groups += [val]
            else
              flash[:notice] = "IP Address #{val} is invalid. Valid examples: 124.124.10.10, 124.124.0.0/16, 124.124.0.0/255.255.0.0"
            end
          else
            collection.default_read_groups += [val]
          end
        else
          flash[:notice] = "#{title.titleize} can't be blank."
        end
      end

      if params["remove_#{title}"].present?
        if ["group", "class", "ipaddress"].include? title
          # This is a hack to deal with the fact that calling default_read_groups#delete isn't marking the record as dirty
          # TODO: Ensure default_read_groups is tracked by ActiveModel::Dirty
          collection.default_read_groups_will_change!
          collection.default_read_groups.delete params["remove_#{title}"]
        else
          # This is a hack to deal with the fact that calling default_read_users#delete isn't marking the record as dirty
          # TODO: Ensure default_read_users is tracked by ActiveModel::Dirty
          collection.default_read_users_will_change!
          collection.default_read_users.delete params["remove_#{title}"]
        end
      end
    end

    update_access_settings(collection, params)

    update_default_lending_period(collection, params) if collection.cdl_enabled?
  end

  def update_access_settings(collection, params)
    if params[:save_field] == "visibility"
      collection.default_visibility = params[:visibility] unless params[:visibility].blank?
    end
    if params[:save_field] == "discovery"
      collection.default_hidden = params[:hidden] == "1"
    end
    if params[:save_field] == "cdl"
      collection.cdl_enabled = params[:cdl] == "1"
    end
  end

  def update_default_lending_period(collection, params)
    if params[:save_field] == "lending_period"
      lending_period = build_default_lending_period(collection)
      if lending_period.positive?
        collection.default_lending_period = lending_period
      elsif lending_period.zero? && params["add_lending_period_days"] && params["add_lending_period_hours"]
        flash[:error] = "Lending period must be greater than 0."
      end
    end
  end

  def build_default_lending_period(collection)
    lending_period = 0
    d = params["add_lending_period_days"].to_i
    h = params["add_lending_period_hours"].to_i
    d.negative? ? collection.errors.add(:lending_period, "days needs to be a positive integer.") : lending_period += d.days
    h.negative? ? collection.errors.add(:lending_period, "hours needs to be a positive integer.") : lending_period += h.hours

    flash[:error] = collection.errors.full_messages.join(' ') if collection.errors.present?
    lending_period.to_i
  rescue
    0
  end

  def apply_access(collection, params)
    BulkActionJobs::ApplyCollectionAccessControl.perform_later(collection.id, params[:overwrite] == "true", params[:save_field]) if params["apply_to_existing"].present?
  end

  def collection_params
    params.permit(:admin_collection => [:name, :description, :unit, :contact_email, :website_label, :website_url, :managers => []])[:admin_collection]
  end

  def check_image_compliance(poster_path)
    fastimage = FastImage.new(poster_path)
    # Size derived from width and aspect ratio from JS code, assets/javascript/crop_upload.js:60-63
    fastimage.type == :png && fastimage.size == [700, 560] # [width, height]
  end
end
