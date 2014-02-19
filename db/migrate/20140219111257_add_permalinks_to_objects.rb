class AddPermalinksToObjects < ActiveRecord::Migration
  def up
    if MINTER.present?
      MediaObject.find_each({},{batch_size:5}) do |mo|
        mo.save(validate: false)
      end
    end
  end

  def down
    MediaObject.find_each({},{batch_size:5}) do |mo|
      mo.permalink = nil
    end
  end
end
