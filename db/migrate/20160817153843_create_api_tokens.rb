class CreateApiTokens < ActiveRecord::Migration
  def change
    create_table :api_tokens do |t|
      t.string :token, null: false
      t.string :username, null: false
      t.string :email, null: false

      t.timestamps
    end
    add_index :api_tokens, :token, unique: true
    add_index :api_tokens, :username
  end
end
