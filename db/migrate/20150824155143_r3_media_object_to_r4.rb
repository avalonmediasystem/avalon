class R3MediaObjectToR4 < ActiveRecord::Migration
  def up
    say_with_time("R3->R4") do
      MediaObject.find_each({'has_model_version_ssim' => 'R3'},{batch_size:5}) { |obj| mediaobject_to_r4(obj) }
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def mediaobject_to_r4(mo)
    say("MediaObject #{mo.pid}", :subitem)
    if mo.descMetadata.identifier.present?
      bib_id = mo.descMetadata.identifier.first
      bib_id_label = mo.descMetadata.identifier.type.first
      mo.descMetadata.bibliographic_id = nil
      mo.descMetadata.add_bibliographic_id(bib_id, bib_id_label)
      mo.descMetadata.add_other_identifier(bib_id, bib_id_label)
      mo.descMetadata.identifier = nil
      mo.save_as_version('R4', validate: false)
    end
  end

end
