class WorkflowStep
  attr_accessor :step, :title, :summary, :template
  
  def initialize(step = nil, title = nil, summary = nil, template = nil)
    self.step = step
    self.title = title
    self.summary = summary
    self.template = template
  end
end
