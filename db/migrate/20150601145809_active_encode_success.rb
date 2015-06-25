class ActiveEncodeSuccess < ActiveRecord::Migration
  def status_code(opts={})
    MasterFile.find_each({'status_code_tesim'=>opts[:from]},{batch_size:5}) do |mf|
      mf.status_code = opts[:to]
      mf.save(validate: false)
    end
  end
  
  def up
    status_code from: 'SUCCEEDED', to: 'COMPLETED'
  end
  
  def down
    status_code from: 'COMPLETED', to: 'SUCCEEDED'
  end
end
