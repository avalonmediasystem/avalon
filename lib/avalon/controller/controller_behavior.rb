module Avalon
  module Controller
    module ControllerBehavior
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def set_default_item_permissions( item, user_key )
          unless item.rightsMetadata.nil?
            item.edit_groups = ["collection_manager"]
            item.apply_depositor_metadata user_key
          end
        end
      end

      def deliver_content
        @obj = ActiveFedora::Base.find(params[:id], :cast => true)
        if can? :inspect, @obj
          ds = @obj.datastreams[params[:datastream]]
          if ds.nil? or ds.new?
            render :text => 'Not Found', :status => :not_found
          else
            render :text => ds.content, :content_type => ds.mimeType
          end
        else
          render :text => 'Unauthorized', :status => :unauthorized
        end
      end

    end
  end
end
