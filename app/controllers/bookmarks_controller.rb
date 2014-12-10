class BookmarksController < CatalogController
  include Blacklight::Bookmarks

  self.document_actions.delete( :email )
  self.document_actions.delete( :citation )

  self.add_document_action( :update_access_control, callback: :access_control_action )
  self.add_document_action( :move, callback: :move_action )
  self.add_document_action( :publish, callback: :publish_action, tool_partial: 'formless_document_action')
  self.add_document_action( :unpublish, callback: :unpublish_action, tool_partial: 'formless_document_action' )
  self.add_document_action( :delete, callback: :delete_action )

  before_filter :verify_permissions, only: :index

  def verify_permissions
    @response, @documents = action_documents
    mos = @documents.collect { |doc| MediaObject.find( doc.id ) }
    @user_actions = self.document_actions.clone
    @user_actions.delete( :delete ) if mos.any? { |mo| cannot? :destroy, mo }
    @user_actions.delete( :unpublish ) if mos.any? { |mo| cannot? :unpublish, mo }
    if mos.any? { |mo| cannot? :update, mo }
      @user_actions.delete( :publish )
      @user_actions.delete( :move )
    end
    @user_actions.delete( :update_access_control ) if mos.any? { |mo| cannot? :update_access_control, mo }
  end

  def access_control_action documents
    errors = []
    success_count = 0
    Array(documents.map(&:id)).each do |id|
      media_object = MediaObject.find(id)
      if cannot? :update_access_control, media_object
        errors += ["#{media_object.title} (#{id}) #{t('blacklight.messages.permission_denied')}."]
      else
        media_object.hidden = params[:hidden] == "true" if params[:hidden].present?
        media_object.visibility = params[:visibility] unless params[:visibility].blank?

	# Limited access stuff
	["group", "class", "user"].each do |title|
	  if params["submit_add_#{title}"].present?
	    if params["#{title}"].present?
	      if ["group", "class"].include? title
		media_object.read_groups += [params["#{title}"].strip]
	      else
		media_object.read_users += [params["#{title}"].strip]
	      end
	    else
	      errors += ["#{title.titleize} can't be blank."]
	    end
	  end

	  if params["submit_remove_#{title}"].present?
	    if params["#{title}"].present?
	      if ["group", "class"].include? title
		media_object.read_groups -= [params["#{title}"]]
	      else
		media_object.read_users -= [params["#{title}"]]
	      end
	    else
	      errors += ["#{title.titleize} can't be blank."]
	    end
          end
	end

        if media_object.save(:validate => false)
          success_count += 1
        else
          errors += ["#{media_object.title} (#{id}) #{t('blacklight.update_access_control.fail')} (#{media_object.errors.full_messages.join(' ')})."] 
        end
      end
    end
    flash[:success] = t("blacklight.update_access_control.success", count: success_count) if success_count > 0
    flash[:alert] = "#{t('blacklight.update_access_control.alert', count: errors.count)}</br> #{ errors.join('<br/> ') }".html_safe if errors.count > 0
  end

  def publish_action documents
    update_status( 'publish', documents )
  end

  def unpublish_action documents
    update_status( 'unpublish', documents )
  end

  def update_status( status, documents )
    errors = []
    success_count = 0
    Array(documents.map(&:id)).each do |id|
      media_object = MediaObject.find(id)
      if cannot? :update, media_object
        errors += ["#{media_object.title} (#{id}) #{t('blacklight.messages.permission_denied')}."]
      else
        case status
        when 'publish'
          media_object.publish!(user_key)
          # additional save to set permalink
          if media_object.save(:validate => false)
            success_count += 1
          else
            errors += ["#{media_object.title} (#{id}) #{t('blacklight.publish.fail')} (#{media_object.errors.full_messages.join(' ')})."] 
          end
        when 'unpublish'
          if can? :unpublish, media_object
            if media_object.publish!(nil)
              success_count += 1
            else
              errors += ["#{media_object.title} (#{id}) #{t('blacklight.unpublish.fail')} (#{media_object.errors.full_messages.join(' ')})."] 
            end
          else
            errors += ["#{media_object.title} (#{id}) #{t('blacklight.messages.permission_denied')}."]
          end
        end
      end
    end
    flash[:success] = t("blacklight.publish.success", count: success_count, status: status) if success_count > 0
    flash[:alert] = "#{t('blacklight.publish.alert', count: errors.count, status: status)}</br> #{ errors.join('<br/> ') }".html_safe if errors.count > 0
  end

  def delete_action documents 
    errors = []
    success_count = 0
    Array(documents.map(&:id)).each do |id|
      media_object = MediaObject.find(id)
      if can? :destroy, media_object
        if media_object.destroy
          success_count += 1
        else
          errors += ["#{media_object.title} (#{id}) #{t('blacklight.delete.fail')} (#{media_object.errors.full_messages.join(' ')})."] 
        end
      else
        errors += ["#{media_object.title} (#{id}) #{t('blacklight.messages.permission_denied')}."]
      end
    end
    flash[:success] = t("blacklight.delete.success", count: success_count) if success_count > 0
    flash[:alert] = "#{t('blacklight.delete.alert', count: errors.count)}</br> #{ errors.join('<br/> ') }".html_safe if errors.count > 0
  end

  def move_action documents
    collection = Admin::Collection.find( params[:target_collection_id] )
    if cannot? :read, collection
      flash[:error] =  t("blacklight.move.error", collection_name: collection.name)
    else
      errors = []
      success_count = 0
      Array(documents.map(&:id)).each do |id|
        media_object = MediaObject.find(id)
        if cannot? :update, media_object
          errors += ["#{media_object.title} (#{id}) #{t('blacklight.messages.permission_denied')}."]
        else
          media_object.collection = collection
          if media_object.save(:validate => false)
            success_count += 1
          else
            errors += ["#{media_object.title} (#{id}) #{t('blacklight.move.fail')} (#{media_object.errors.full_messages.join(' ')})."] 
          end
        end
      end    
      flash[:success] = t("blacklight.move.success", count: success_count, collection_name: collection.name) if success_count > 0
      flash[:alert] = "#{t('blacklight.move.alert', count: errors.count)}</br> #{ errors.join('<br/> ') }".html_safe if errors.count > 0
    end
  end

end
