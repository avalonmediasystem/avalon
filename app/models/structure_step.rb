  class StructureStep < Hydrant::Workflow::BasicStep
    def initialize(step = 'structure', title = "Structure", summary = "Organization of resources", template = 'structure')
      super
    end

    def execute context
      media_object = context[:mediaobject]

        if ! context[:masterfile_ids].nil?

          # gather the parts in the right order
          # in this situation we cannot use MatterFile.find([]) because
          # it will not return the results in the correct order
          master_files = context[:masterfile_ids].map{ |masterfile_id| MasterFile.find(masterfile_id) }

          # re-add the parts that are now in the right order
          media_object.parts_with_order = master_files

          media_object.save 
        end
      context
    end
  end
