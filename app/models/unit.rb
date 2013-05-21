require "role_controls"

class Unit < ActiveRecord::Base
  attr_accessible :name
  validates :name, length: { minimum: 10 }

end