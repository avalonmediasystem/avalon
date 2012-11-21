	class PreviewStep < Hydrant::Workflow::BasicStep
                def initialize(step = 'preview', 
                               title = "Preview and publish", 
                               summary = "Release the item for use", 
                               template = 'preview')
                  super
                end

		def execute context
		  mediaobject = context[:mediaobject]
	          # Publish the media object
	          mediaobject.avalon_publisher = context[:user]
	          mediaobject.save
		  context
		end
	end
