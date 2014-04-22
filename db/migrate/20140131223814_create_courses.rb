class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.string :context_id
      t.text :label
      t.timestamps
    end
  end
end
