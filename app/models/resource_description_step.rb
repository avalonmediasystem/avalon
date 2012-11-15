	class ResourceDescriptionStep < Hydrant::Workflow::BasicStep
                def initialize(step = 'resource-description', title = "Resource description", summary = "Metadata about the item", template = 'basic_metadata')
                  super
                end

		def execute context
		  mediaobject = context[:mediaobject]
	          logger.debug "<< Populating required metadata fields >>"
		  mediaobject.update_datastream(:descMetadata, context[:media_object])
	          logger.debug "<< Updating descriptive metadata >>"
	          mediaobject.save
		  context
		end
	end
