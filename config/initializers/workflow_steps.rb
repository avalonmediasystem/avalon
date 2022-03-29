Rails.application.config.to_prepare do
  HYDRANT_STEPS = Avalon::Workflow::Workflow.new(FileUploadStep.new,
                                                 ResourceDescriptionStep.new,
                                                 StructureStep.new,
                                                 AccessControlStep.new)
end
