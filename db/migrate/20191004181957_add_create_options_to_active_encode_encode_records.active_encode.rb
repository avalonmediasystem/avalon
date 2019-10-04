# frozen_string_literal: true
# This migration comes from active_encode (originally 20190702153755)
class AddCreateOptionsToActiveEncodeEncodeRecords < ActiveRecord::Migration[5.0]
  def change
    add_column :active_encode_encode_records, :create_options, :text
  end
end
