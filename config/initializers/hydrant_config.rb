    # Q & D
    step_one = IngestStep.new('file-upload', 'Manage files',
      'Associated bitstreams', 'file_upload')
    step_two = IngestStep.new('resource-description', 'Resource description',
      'Metadata about the item', 'basic_metadata')
    step_three = IngestStep.new('access-control', 'Access control',
      'Who can access the item', 'access_control')
    step_four = IngestStep.new('preview', 'Preview and publish',
      'Release the item for use', 'preview')
    
    HYDRANT_STEPS = IngestWorkflow.new(step_one, step_two, step_three, step_four)
