class AddFullNameToUser < ActiveRecord::Migration
  def change
    add_column :users, :full_name, :string, :after => :email
  end
end
