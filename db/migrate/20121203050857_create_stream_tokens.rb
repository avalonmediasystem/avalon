class CreateStreamTokens < ActiveRecord::Migration
  def change
    create_table :stream_tokens do |t|
    	t.string   :token
    	t.string   :target
    	t.datetime :expires
    end
  end
end
