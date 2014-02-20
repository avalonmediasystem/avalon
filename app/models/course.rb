class Course < ActiveRecord::Base
  attr_accessible :context_id, :label, :title

  def self.autocomplete(query)
    self.where("label LIKE :q OR title LIKE :q", q: "%#{query}%").collect { |course|
      { id: course.context_id, display: course.title }
    }
  end
end
