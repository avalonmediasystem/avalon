class RemoveHydraMigrate < ActiveRecord::Migration
  def up
    say_with_time('remove migrationInfo') do
      ActiveFedora::Base.find_each({},{batch_size:5, cast:true}) do |obj|
        if obj.is_a?(VersionableModel)
          version = nil
          if obj.datastreams.has_key?('migrationInfo')
            datastream = obj.datastreams['migrationInfo']
            migration_info = Nokogiri::XML(datastream.content)
            version = migration_info.xpath('//mi:current',{ 'mi' => "http://hydra-collab.stanford.edu/schemas/migrationInfo/v1" }).first
            version = version.text unless version.nil?
            say("#{obj.class} #{obj.pid}", :subitem)
            datastream.delete
          end
          obj.save_as_version(version, validate: false) unless version.nil?
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
