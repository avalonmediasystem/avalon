class CreateUnitUsersJoinTable < ActiveRecord::Migration
  def change
    create_table 'units_users', :id => false do |t|
      t.column 'unit_id', :integer
      t.column 'user_id', :integer
    end
  end
end
