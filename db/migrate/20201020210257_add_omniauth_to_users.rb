class AddOmniauthToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :display_name, :string
    add_column :users, :ppid, :string
  end
end
