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

		  #context[:groups] and context[:users] is only for deletion and should be renamed in the access_control form and here
                  unless context[:groups].blank?
                    groups = mediaobject.group_exceptions
                    context[:groups].each {|g| groups.delete g }
                    mediaobject.group_exceptions = groups
                  end                
                  unless context[:users].blank?
                    users = mediaobject.user_exceptions
                    context[:users].each {|u| users.delete u }
                    mediaobject.user_exceptions = users
                  end                

                  if context[:scope] == "Group"
                    groups = mediaobject.group_exceptions
                    groups << context[:value] unless context[:value].blank?
                    mediaobject.group_exceptions = groups
                  elsif context[:scope] == "User"
                    users = mediaobject.user_exceptions
                    users << context[:value] unless context[:value].blank?
                    mediaobject.user_exceptions = users
                  end

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
