class BookmarksController < CatalogController
  include Blacklight::Bookmarks

  self.document_actions.delete( :email )
  self.document_actions.delete( :citation )

  self.add_action( :move, :move_action )
  self.add_action( :publish, :publish_action, {formless: true} )
  self.add_action( :unpublish, :unpublish_action, {formless: true} )
  self.add_action( :delete, :delete_action )

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
          media_object.save( validate: false )
          success_count += 1
        when 'unpublish'
          if can? :unpublish, media_object
            media_object.publish!(nil)
            success_count += 1
          else
            errors += ["#{media_object.title} (#{id}) #{t('blacklight.messages.permission_denied')}."]
          end
        end
      end
    end
    flash[:success] = t("blacklight.publish.success", count: success_count, status: status) if success_count > 0
    flash[:alert] = "#{t(blacklight.publish.alert, count: errors.count)}</br> #{ errors.join('<br/> ') }" if errors.count > 0
  end

  def delete_action documents 
    errors = []
    success_count = 0
    Array(documents.map(&:id)).each do |id|
      media_object = MediaObject.find(id)
      if can? :destroy, media_object
        media_object.destroy
        success_count += 1
      else
        errors += ["#{media_object.title} (#{id}) #{t('blacklight.messages.permission_denied')}."]
      end
    end
    flash[:success] = t("blacklight.delete.success", count: success_count) if success_count > 0
    flash[:alert] = "#{t(blacklight.delete.alert, count: errors.count)}</br> #{ errors.join('<br/> ') }" if errors.count > 0
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
          media_object.save(:validate => false)
          success_count += 1
        end
      end    
      flash[:success] = t("blacklight.move.success", count: success_count, collection_name: collection.name) if success_count > 0
      flash[:alert] = "#{t(blacklight.move.alert, count: errors.count)}</br> #{ errors.join('<br/> ') }" if errors.count > 0
    end
  end

end
