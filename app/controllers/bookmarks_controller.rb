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

class BookmarksController < CatalogController

  before_action :authenticate_user!

  include Blacklight::Bookmarks

  #HACK next two lines are a hack for problems in the puppet VM tomcat/solr
    # BookmarksController.search_params_logic -= [:add_query_to_solr]
    # BookmarksController.search_params_logic += [:rewrite_bookmarks_search]

  blacklight_config.show.document_actions[:email].if = false if blacklight_config.show.document_actions[:email]
  blacklight_config.show.document_actions[:citation].if = false if blacklight_config.show.document_actions[:citation]

  blacklight_config.add_show_tools_partial( :update_access_control, callback: :access_control_action, if: Proc.new { |context, config, options| context.user_can? :update_access_control } )

  blacklight_config.add_show_tools_partial( :move, callback: :move_action, if: Proc.new { |context, config, options| context.user_can? :move } )

  blacklight_config.add_show_tools_partial( :publish, callback: :status_action, modal: false, component: FormlessDocumentActionComponent, if: Proc.new { |context, config, options| context.user_can? :publish } )

  blacklight_config.add_show_tools_partial( :unpublish, callback: :status_action, modal: false, component: FormlessDocumentActionComponent, if: Proc.new { |context, config, options| context.user_can? :unpublish } )

  blacklight_config.add_show_tools_partial( :delete, callback: :delete_action, if: Proc.new { |context, config, options| context.user_can? :delete } )

  blacklight_config.add_show_tools_partial( :add_to_playlist, callback: :add_to_playlist_action )

  blacklight_config.add_show_tools_partial( :intercom_push, callback: :intercom_push_action, if: Proc.new { |context, config, options| context.user_can? :intercom_push } )

  blacklight_config.add_show_tools_partial( :merge, callback: :merge_action, if: Proc.new { |context, config, options| context.user_can? :merge } )

  before_action :verify_permissions, only: :index

  #HACK next two methods are a hack for problems in the puppet VM tomcat/solr
  # def rewrite_bookmarks_search(solr_parameters, user_parameters)
  #   solr_parameters[:q] = "id:(#{ Array(user_parameters[:q][:id]).map { |x| solr_escape(x) }.join(' OR ')})"
  # end

  # def solr_escape val, options={}
  #   options[:quote] ||= '"'
  #   unless val =~ /^[a-zA-Z0-9$_\-\^]+$/
  #     val = options[:quote] +
  #       # Yes, we need crazy escaping here, to deal with regexp esc too!
  #       val.gsub("'", "\\\\\'").gsub('"', "\\\\\"") +
  #       options[:quote]
  #   end
  #   return val
  # end


  def user_can? action
    @valid_user_actions.include? action
  end

  def verify_permissions
    @response = action_documents
    @valid_user_actions = [:delete, :unpublish, :publish, :merge, :move, :update_access_control, :add_to_playlist]
    @valid_user_actions += [:intercom_push] if Settings.intercom.present?
    Array(@response).each do |doc|
      mo = SpeedyAF::Proxy::MediaObject.find(doc.id)
      @valid_user_actions.delete :delete if @valid_user_actions.include? :delete and cannot? :destroy, mo
      @valid_user_actions.delete :unpublish if @valid_user_actions.include? :unpublish and cannot? :unpublish, mo
      @valid_user_actions.delete :publish if @valid_user_actions.include? :publish and cannot? :update, mo
      @valid_user_actions.delete :merge if @valid_user_actions.include? :merge and cannot? :update, mo
      @valid_user_actions.delete :move if @valid_user_actions.include? :move and cannot? :move, mo
      @valid_user_actions.delete :update_access_control if @valid_user_actions.include? :update_access_control and cannot? :update_access_control, mo
      @valid_user_actions.delete :intercom_push if @valid_user_actions.include? :intercom_push and cannot? :intercom_push, mo
    end
  end

  # def index
  #   @bookmarks = token_or_current_or_guest_user.bookmarks
  #   bookmark_ids = @bookmarks.collect { |b| b.document_id.to_s }
  #
  #   @response = get_solr_response_for_document_ids(bookmark_ids, defType: 'edismax')
  #
  #   respond_to do |format|
  #     format.html { }
  #     format.rss  { render :layout => false }
  #     format.atom { render :layout => false }
  #     format.json do
  #       render json: render_search_results_as_json
  #     end
  #
  #     additional_response_formats(format)
  #     document_export_formats(format)
  #   end
  # end

  # def action_documents (R5)
  #   bookmarks = token_or_current_or_guest_user.bookmarks
  #   bookmark_ids = bookmarks.collect { |b| b.document_id.to_s }
  #   get_solr_response_for_document_ids(bookmark_ids, rows: bookmark_ids.count, defType: 'edismax')
  # end

  def count
    respond_to do |format|
      format.html
      format.json { render json: { count: current_or_guest_user.bookmarks.count } }
    end
  end

  def action_documents
    bookmarks = token_or_current_or_guest_user.bookmarks
    bookmark_ids = bookmarks.collect { |b| b.document_id.to_s }
    search_service.fetch(bookmark_ids, rows: bookmark_ids.count)
  end

  def access_control_action documents
    params.permit! # FIXME: lock this down eventually
    errors = []
    success_ids = []
    Array(documents.map(&:id)).each do |id|
      media_object = SpeedyAF::Proxy::MediaObject.find(id)
      if cannot? :update_access_control, media_object
        errors += ["#{media_object.title} (#{id}) #{t('blacklight.messages.permission_denied')}."]
      else
        success_ids << id
      end
    end
    flash[:success] = t("blacklight.update_access_control.success", count: success_ids.count) if success_ids.count > 0
    flash[:alert] = "#{t('blacklight.update_access_control.alert', count: errors.count)}</br> #{ errors.join('<br/> ') }".html_safe if errors.count > 0

    params[:hidden] = params[:hidden] == "true" if params[:hidden].present?
    BulkActionJobs::AccessControl.perform_later success_ids, params.to_h
  end

  def add_to_playlist_action documents
    playlist = Playlist.find(params[:target_playlist_id])
    Array(documents.map(&:id)).each do |id|
      media_object = SpeedyAF::Proxy::MediaObject.find(id)
      media_object.sections.each do |mf|
        clip = AvalonClip.create(master_file: mf)
        PlaylistItem.create(clip: clip, playlist: playlist)
      end
    end
  end

  def status_action documents
    errors, success_ids = [], [], []
    Array(documents.map(&:id)).each do |id|
      media_object = SpeedyAF::Proxy::MediaObject.find(id)
      if cannot? :update, media_object
        errors += ["#{media_object.title} (#{id}) #{t('blacklight.messages.permission_denied')}."]
      else
        case params['action']
        when 'publish'
          if media_object.title.nil?
            errors += ["#{id}, Unable to Publish Item. Missing required fields."]
          else
            success_ids << id
          end
        when 'unpublish'
          if can? :unpublish, media_object
            success_ids << id
          else
            errors += ["#{media_object.title} (#{id}) #{t('blacklight.messages.permission_denied')}."]
          end
        end
      end
    end
    flash[:success] = t("blacklight.status.success", count: success_ids.count, status: params['action']) if success_ids.count > 0
    flash[:alert] = "#{t('blacklight.status.alert', count: errors.count, status: params['action'])}</br> #{ errors.join('<br/> ') }".html_safe if errors.count > 0
    BulkActionJobs::UpdateStatus.perform_later success_ids, current_user.user_key, params.permit('action').to_h
  end

  def delete_action documents
    errors = []
    success_ids = []
    Array(documents.map(&:id)).each do |id|
      media_object = SpeedyAF::Proxy::MediaObject.find(id)
      if can? :destroy, media_object
        success_ids << id
      else
        errors += ["#{media_object.title} (#{id}) #{t('blacklight.messages.permission_denied')}."]
      end
    end
    flash[:success] = t("blacklight.delete.success", count: success_ids.count) if success_ids.count > 0
    flash[:alert] = "#{t('blacklight.delete.alert', count: errors.count)}</br> #{ errors.join('<br/> ') }".html_safe if errors.count > 0
    BulkActionJobs::Delete.perform_later success_ids, nil
  end

  def move_action documents
    collection = SpeedyAF::Proxy::Admin::Collection.find(params[:target_collection_id])
    if cannot? :read, collection
      flash[:error] = t("blacklight.move.error", collection_name: collection.name)
    else
      errors = []
      success_ids = []
      Array(documents.map(&:id)).each do |id|
        media_object = SpeedyAF::Proxy::MediaObject.find(id)
        if cannot? :move, media_object
          errors += ["#{media_object.title} (#{id}) #{t('blacklight.messages.permission_denied')}."]
        else
          success_ids << id
        end
      end
      flash[:success] = t("blacklight.move.success", count: success_ids.count, collection_name: collection.name) if success_ids.count > 0
      # Upstream logic in Blacklight creates a success message if one is not already set:
      # https://github.com/projectblacklight/blacklight/blob/main/app/builders/blacklight/action_builder.rb
      # This causes the full success message hash to be generated in the flash message because a count is not
      # available to be passed in. Flash.now temporarily sets the message so blacklight does not create
      # one, but clears itself out before the page actually renders.
      flash.now[:success] = "" if success_ids.count.zero?
      flash[:alert] = "#{t('blacklight.move.alert', count: errors.count)}</br> #{ errors.join('<br/> ') }".html_safe if errors.count > 0
      BulkActionJobs::Move.perform_later success_ids, params.permit(:target_collection_id).to_h if success_ids.count.positive?
    end
  end

  def intercom_push_action documents
    errors = []
    success_ids = []
    intercom = Avalon::Intercom.new(current_user.user_key)
    collections = intercom.user_collections(true)
    session[:intercom_collections] = collections
    if intercom.collection_valid?(params[:collection_id])
      Array(documents.map(&:id)).each do |id|
        media_object = SpeedyAF::Proxy::MediaObject.find(id)
        if cannot? :intercom_push, media_object
          errors += ["#{media_object.title} (#{id}) #{t('blacklight.messages.permission_denied')}."]
        else
          success_ids << id
        end
      end
      if success_ids.present?
        session[:intercom_default_collection] = params[:collection_id]
        BulkActionJobs::IntercomPush.perform_later success_ids, current_user.user_key, params.permit(:collection_id, :include_structure).to_h
        flash[:success] = "Sucessfully started push of #{success_ids.count} media objects."
      end
      flash[:alert] = "Failed to push #{errors.count} media objects.</br> #{ errors.join('<br/> ') }".html_safe if errors.count > 0
    else
      flash[:alert] = "You do not have permission to push to this collection."
    end
  end

  def merge_action documents
    errors = []
    target = SpeedyAF::Proxy::MediaObject.find params[:media_object]
    subject_ids = documents.collect(&:id)
    subject_ids.delete(target.id)
    subject_ids.map { |id| SpeedyAF::Proxy::MediaObject.find id }.each do |media_object|
      if cannot? :destroy, media_object
        errors += ["#{media_object.title || id} #{t('blacklight.messages.permission_denied')}."]
      end
    end

    if errors.present?
      flash[:error] = "#{t('blacklight.merge.fail', count: errors.count)} #{errors.join('<br>')}".html_safe
    else
      BulkActionJobs::Merge.perform_later target.id, subject_ids.sort
      flash[:success] = t("blacklight.merge.success", count: subject_ids.count, item_link: media_object_path(target), item_title: target.title || target.id).html_safe
    end
  end

  # Ensure that current_ability is included in the search context
  def search_service_context
    super.merge({ current_ability: current_ability })
  end
end
