    # Q & D
    file_upload = IngestStep.new('file-upload', 'Manage file(s)',
      'Associated bitstreams', 'file_upload')
    structure = IngestStep.new('structure', 'Structure',
      'Organization of resources', 'structure')
    metadata = IngestStep.new('resource-description', 'Resource description',
      'Metadata about the item', 'basic_metadata')
    access_control = IngestStep.new('access-control', 'Access control',
      'Who can access the item', 'access_control')
    content_preview = IngestStep.new('preview', 'Preview and publish',
      'Release the item for use', 'preview')
    
    HYDRANT_STEPS = IngestWorkflow.new(metadata, file_upload, structure, access_control, content_preview)
