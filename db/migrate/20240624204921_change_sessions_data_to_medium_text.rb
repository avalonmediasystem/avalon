class ChangeSessionsDataToMediumText < ActiveRecord::Migration[7.0]
  def change
    change_column :sessions, :data, :text, limit: 16777215
  end
end
