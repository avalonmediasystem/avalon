	class AccessControlStep < Hydrant::Workflow::BasicStep
		def initialize(step = 'access-control', 
                               title = "Access Control", 
                               summary = "Who can access the item", 
                               template = 'access_control')
		  super
		end

		def execute context
		  mediaobject = context[:mediaobject]
	          # TO DO: Implement me
        	  logger.debug "<< Access flag = #{context[:access]} >>"
              	  mediaobject.access = context[:access] unless context[:access].blank? 

		  groups = mediaobject.groups
                  groups << context[:add_group] unless context[:add_group].blank?
                  groups.delete context[:del_group] unless context[:del_group].blank?
                  mediaobject.groups = groups

		  users = mediaobject.users
                  users << context[:add_user] unless context[:add_user].blank?
                  users.delete context[:del_user] unless context[:del_user].blank?
                  mediaobject.users = users

        
	          mediaobject.save
        	  logger.debug "<< Groups : #{mediaobject.read_groups} >>"
        	  logger.debug "<< Users : #{mediaobject.read_users} >>"
		  context
		end
	end
