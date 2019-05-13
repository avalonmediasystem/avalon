# This migration comes from blacklight (originally 20140202020201)
# frozen_string_literal: true
class CreateSearches < ActiveRecord::Migration[5.1]
  def self.up
    create_table :searches do |t|
      t.text  :query_params
      t.integer :user_id, index: true
      t.string :user_type

      t.timestamps null: false
    end
  end

  def self.down
    drop_table :searches
  end
end
