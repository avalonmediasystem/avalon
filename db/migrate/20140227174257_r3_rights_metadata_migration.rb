class R3RightsMetadataMigration < ActiveRecord::Migration
  def up
    MediaObject.find_each({},{batch_size:5}) do |mo|
      mo.read_users += find_user_exceptions(mo.rightsMetadata.ng_xml)
      mo.read_groups += find_group_exceptions(mo.rightsMetadata.ng_xml)
      remove_exceptions_node!(mo.rightsMetadata.ng_xml)
      mo.save(validate: false)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def find_user_exceptions(xml)
    xml.xpath("//rm:access[@type='exceptions']/rm:machine/rm:person", {'rm' => 'http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1'}).map {|n| n.text }
  end

  def find_group_exceptions(xml)
    xml.xpath("//rm:access[@type='exceptions']/rm:machine/rm:group", {'rm' => 'http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1'}).map {|n| n.text }
  end

  def remove_exceptions_node!(xml)
    xml.xpath("//rm:access[@type='exceptions']", {'rm' => 'http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1'}).first.remove
  end
end
