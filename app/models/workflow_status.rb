class WorkflowStatus < ActiveRecord::Base
  attr_accessible :pid, :current_step, :complete

  # Maybe there should be some validation down the road. For now assume it is all in
  # place
end
