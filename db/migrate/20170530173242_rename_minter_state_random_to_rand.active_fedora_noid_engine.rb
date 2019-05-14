# This migration comes from active_fedora_noid_engine (originally 20161021203429)
# frozen_string_literal: true
class RenameMinterStateRandomToRand < ActiveRecord::Migration[5.1]
  def change
    rename_column :minter_states, :random, :rand
  end
end
