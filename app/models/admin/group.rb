class Admin::Group
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Conversion
  
  # For now this list is a hardcoded constant. Eventually it might be more flexible
  # as more thought is put into the process of providing a comment
  attr_accessor :name, :users

  validates :name, presence: {message: "Name is a required field"}
  
  def initialize(attributes = {})
    @saved = false
    @users = []
    attributes.each do |k, v|
      send("#{k}=", v)
    end
  end
  
  def resources
    res = []
    # TODO: this is very costly
    MediaObject.find(:all).each do |mediaobject|
      if mediaobject.read_groups.include? @name
        res << mediaobject.pid
      end
    end
    
    res
  end
  
  def id 
    @name
  end
  
  # Necessary hack so that form_for works with both :new and :edit
  def save 
    @saved = true
  end
  
  # Stub this method out so that form_for functions as expected even though there is no database backing the Group model
  def persisted?
    @saved
  end
  
private

  def saved 
    self[:saved]
  end
  
  def saved=(val)
    self[:saved] = val
  end
  
end
