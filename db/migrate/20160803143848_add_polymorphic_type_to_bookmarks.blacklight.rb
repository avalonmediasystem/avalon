# This migration comes from blacklight (originally 20140320000000)
# frozen_string_literal: true
class AddPolymorphicTypeToBookmarks < ActiveRecord::Migration[5.1]
  def change
    add_column(:bookmarks, :document_type, :string) unless Bookmark.connection.column_exists? :bookmarks, :document_type
    
    add_index :bookmarks, :user_id unless Bookmark.connection.index_exists? :bookmarks, :user_id
  end
end
