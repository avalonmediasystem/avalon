require 'role_controls'

class Unit < ActiveRecord::Base
  belongs_to :created_by_user, primary_key: 'username', foreign_key: 'created_by_user_id', class_name: 'User'
  has_and_belongs_to_many :managers, join_table: 'units_users', class_name: 'User'

  attr_accessible :name
  validates :name, length: { minimum: 4 }, uniqueness: { :case_sensitive => false }

  def self.searchable_fields
    [ 
      :name 
    ] 
  end
end