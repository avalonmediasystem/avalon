class CreateCheckouts < ActiveRecord::Migration[6.0]
  def change
    create_table :checkouts do |t|
      t.references :user, foreign_key: true
      t.string :media_object_id
      t.datetime :checkout_time
      t.datetime :return_time

      t.timestamps
    end
  end
end
