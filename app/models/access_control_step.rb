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
              	  mediaobject.access = context[:access] unless context[:access].blank? 

                  if context[:commit] == "Add"
                    if context[:scope] == "Group"
                      groups = mediaobject.group_exceptions
                      groups << context[:value] unless context[:value].blank?
                      mediaobject.group_exceptions = groups
                    elsif context[:scope] == "User"
                      users = mediaobject.user_exceptions
                      users << context[:value] unless context[:value].blank?
                      mediaobject.user_exceptions = users
                    end
                  elsif context[:commit] == "Delete"
                    if context[:scope] == "Group"
                      groups = mediaobject.group_exceptions
                      groups.delete context[:value] unless context[:value].blank?
                      mediaobject.group_exceptions = groups
                    elsif context[:scope] == "User"
                      users = mediaobject.user_exceptions
                      users.delete context[:value] unless context[:value].blank?
                      mediaobject.user_exceptions = users
                    end
                  end
        
	          mediaobject.save
        	  logger.debug "<< Groups : #{mediaobject.read_groups} >>"
        	  logger.debug "<< Users : #{mediaobject.read_users} >>"
		  context
		end
	end
