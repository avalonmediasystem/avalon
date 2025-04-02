# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

class AddAnnotationsClipsMarkers < ActiveRecord::Migration[5.1]
  def change
    create_table :annotations do |t|
      t.string :uuid
      t.string :source_uri
      t.references :playlist_item, null: true, index: true
      t.text   :annotation
      t.string :type
    end
    add_index :annotations, :type
    create_table :playlists do |t|
      t.string :title
      t.references :user, null: false, index: true
      t.string :comment
      t.string :visibility
      t.timestamps
    end
    create_table :playlist_items do |t|
      t.references :playlist, null: false, index: true
      t.references :annotation, null: false, index: true
      t.integer :position
      t.timestamps
    end
    rename_column :playlist_items, :annotation_id, :clip_id
  end
end
