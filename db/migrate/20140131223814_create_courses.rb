class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.string :guid
      t.text :label
      t.timestamps
    end
  end
end
