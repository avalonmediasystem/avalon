	class StructureStep < Hydrant::Workflow::BasicStep
                def initialize(step = 'structure', title = "Structure", summary = "Organization of resources", template = 'structure')
                  super
                end

		def execute context
		  mediaobject = context[:mediaobject]

        if !context[:masterfile_ids].nil?
          masterFiles = []
          context[:masterfile_ids].each do |mf_id|
            mf = MasterFile.find(mf_id)
            masterFiles << mf
          end

          # Clean out the parts
          masterFiles.each do |mf|
            mediaobject.parts_remove mf
          end
          mediaobject.save(validate: false)
          
          # Puts parts back in order
          masterFiles.each do |mf|
            mf.container = mediaobject
            mf.save
          end
          mediaobject.save(validate: false)
        end
		  context
		end
	end
