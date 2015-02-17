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
