	class AccessControlStep < Hydrant::Workflow::BasicStep
		def initialize(step = 'access-control', 
                   title = "Access Control", 
                   summary = "Who can access the item", 
                   template = 'access_control')
		  super
		end

		def execute context
      logger.debug "<<< In access control step: #{context.inspect} >>>"
		  mediaobject = context[:mediaobject]
      # TO DO: Implement me
      logger.debug "<< Access flag = #{context[:access]} >>"


      # Limited access stuff
      if context[:delete_group].present?
        groups = mediaobject.read_groups
        groups.delete context[:delete_group]
        mediaobject.read_groups = groups
      end 
      if context[:delete_user].present?
        users = mediaobject.read_users
        users.delete context[:delete_user]
        mediaobject.read_users = users
      end 

      if context[:commit] == "Add Group"
        groups = mediaobject.group_exceptions
        groups << context[:new_group] unless context[:new_group].blank?
        mediaobject.group_exceptions = groups
      elsif context[:commit] == "Add User"
        users = mediaobject.user_exceptions
        users << context[:new_user] unless context[:new_user].blank?
        mediaobject.user_exceptions = users
        puts "EXCEPTIONS #{MediaObject.find(mediaobject.pid).group_exceptions.inspect}"
      end

      mediaobject.access = context[:access] unless context[:access].blank? 

      unless context[:media_object].blank? or context[:media_object][:hidden].blank?
        logger.debug "<< Hidden = #{context[:media_object][:hidden]} >>"
        mediaobject.hidden = context[:media_object][:hidden] == "1"
      end

      mediaobject.save
      logger.debug "<< Groups : #{mediaobject.read_groups} >>"
      logger.debug "<< Users : #{mediaobject.read_users} >>"
		  context
		end
	end
