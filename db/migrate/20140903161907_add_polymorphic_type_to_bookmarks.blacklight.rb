# This migration comes from blacklight (originally 20140320000000)
# -*- encoding : utf-8 -*-
class AddPolymorphicTypeToBookmarks < ActiveRecord::Migration
  def change
    add_column(:bookmarks, :document_type, :string)
    
    add_index :bookmarks, :user_id
  end
end
