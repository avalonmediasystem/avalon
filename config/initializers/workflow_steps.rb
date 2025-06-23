Rails.application.config.to_prepare do
  HYDRANT_STEPS = Workflow.new(FileUploadStep.new,
                               ResourceDescriptionStep.new,
                               StructureStep.new,
                               AccessControlStep.new)
end
