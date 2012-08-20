class IngestStatus < ActiveRecord::Base
  attr_accessible :pid, :current_step, :complete
end
