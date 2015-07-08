class IncreaseSessionData < ActiveRecord::Migration
  def change
     change_column :sessions, :data, :text, :limit => (16.megabytes-1)
  end
end
