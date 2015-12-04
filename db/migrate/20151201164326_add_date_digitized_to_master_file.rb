class AddDateDigitizedToMasterFile < ActiveRecord::Migration

  def up
    MasterFile.find_each({},{batch_size:5}) do |mf|
      encode = ActiveEncode::Base.find(mf.workflow_id)
      next unless encode.present?
      mf.date_digitized = encode.finished_at
      mf.save(validate: false)
    end
  end

  def down
    MasterFile.find_each({},{batch_size:5}) do |mf|
      mf.date_digitized = nil
      mf.save(validate: false)
    end
  end

end
