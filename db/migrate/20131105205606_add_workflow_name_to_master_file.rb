class AddWorkflowNameToMasterFile < ActiveRecord::Migration
  def change
    MasterFile.all.each do |master_file|
      unless master_file.mhMetadata.workflow_name.present?
        if master_file.file_format == 'Sound'
          master_file.mhMetadata.workflow_name = 'fullaudio'
        elsif master_file.file_format == 'Moving image'
          master_file.mhMetadata.workflow_name = 'avalon'
        end
        master_file.save( validate: false )
      end
    end
  end

end
