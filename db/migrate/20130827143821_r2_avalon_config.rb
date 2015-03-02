# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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
