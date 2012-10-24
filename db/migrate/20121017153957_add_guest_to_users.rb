class AddGuestToUsers < ActiveRecord::Migration
  def change
    add_column :users, :guest, :string
  end
end
