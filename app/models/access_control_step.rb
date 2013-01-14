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
              	  mediaobject.access = context[:access]        

		  mediaobject.groups = context[:groups]
		  mediaobject.users = context[:users]
        
	          mediaobject.save
        	  logger.debug "<< Groups : #{mediaobject.read_groups} >>"
        	  logger.debug "<< Users : #{mediaobject.read_users} >>"
		  context
		end
	end
