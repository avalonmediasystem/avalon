class R2AvalonConfig < ActiveRecord::Migration
  def up
    avalon_yml = File.join(Rails.root,'config/avalon.yml')
    raw_config = YAML.load(File.read(avalon_yml))
    raw_config.values.each do |config|
      config['ffmpeg'] ||= { 'path'=>'/usr/bin/ffmpeg' }
      config['groups'] ||= { 'system_groups'=>[] }
      config['groups']['system_groups'] |= ['administrator', 'manager', 'group_manager']
      config['controlled_vocabulary'] ||= { 'path'=>'config/controlled_vocabulary.yml' }
    end
    File.open(avalon_yml,'w') { |yml| YAML.dump(raw_config,yml) }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
