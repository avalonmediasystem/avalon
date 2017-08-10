class CreateBatchEntries < ActiveRecord::Migration
  def change
    create_table :batch_entries do |t|
      t.string 'bibliographic_id_label'
      t.string 'bibliographic_id'
      t.string 'other_identifier_type'
      t.string 'other_identifier'
      t.string 'title', null: false
      t.string 'creator'
      t.string 'contributor'
      t.string 'genre'
      t.string 'publisher'
      t.string 'date_created'
      t.string 'date_issued', null: false
      t.text   'abstract', limit: 4294967295
      t.string 'language'
      t.string 'physical_description'
      t.string 'related_item_label'
      t.string 'related_item_url'
      t.string 'topical_subject'
      t.string 'geographic_subject'
      t.string 'temporal_subject'
      t.string 'terms_of_use'
      t.string 'table_of_contents'
      t.string 'note_type1'
      t.string 'note1'
      t.string 'note_type2'
      t.string 'note2'
      t.string 'publish'
      t.string 'hidden'
      t.string 'file'
      t.string 'label'
      t.string 'offset'
      t.string 'skip-transcoding'
      t.string 'absolute_location'
      t.belongs_to :batch_registry, index: true
      t.string 'status'
      t.string 'error'
      t.datetime 'loaded_at'
      t.datetime 'last_modified'
      t.boolean 'ingested'
    end
  end
end
