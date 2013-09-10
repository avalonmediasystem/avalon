class EnsureDurationIsCorrect < ActiveRecord::Migration
  def change
    MediaObject.where({}).each do |media_object|
      media_object.populate_duration!
      media_object.save( validate: false )
    end
  end
end
