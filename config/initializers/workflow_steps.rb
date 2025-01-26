Rails.application.config.to_prepare do
  HYDRANT_STEPS = Avalon::Workflow::Workflow.new(FileUploadStep.new,
                                                 ResourceDescriptionStep.new,
                                                 StructureStep.new,
                                                 AccessControlStep.new)
  
  # Override context building so edit page rendering skips fedora
  Avalon::Workflow::WorkflowControllerBehavior.class_eval do
    def model_object
      @model_object = if params[:action] == "edit"
                        SpeedyAF::Base.find(params[:id])
                      else
                        ActiveFedora::Base.find(params[:id], cast: true)
                      end
    end

    # def perform_step_action action
    #   context = if action == :before_step
    #               HYDRANT_STEPS.get_step(@active_step).send(action, params.merge!({ user: user_key }))
    #             else
    #               HYDRANT_STEPS.get_step(@active_step).send(action, build_context)
    #             end

    #   context_to_instance_variables context
    #   context
    # end
  end
end
