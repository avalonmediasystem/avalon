HYDRANT_STEPS = Hydrant::Workflow::Workflow.new(FileUploadStep.new, 
						ResourceDescriptionStep.new, 
						StructureStep.new, 
						AccessControlStep.new, 
						PreviewStep.new)
