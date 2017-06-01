# This migration comes from active_fedora_noid_engine (originally 20160610010003)
# frozen_string_literal: true
class CreateMinterStates < ActiveRecord::Migration
  def change
    create_table :minter_states do |t|
      t.string :namespace, null: false, default: 'default'
      t.string :template, null: false
      t.text :counters
      t.bigint :seq, default: 0
      t.binary :random
      t.timestamps null: false
    end
    # Use both model and DB-level constraints for consistency while scaling horizontally
    add_index :minter_states, :namespace, unique: true
  end
end
