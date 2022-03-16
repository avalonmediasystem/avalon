# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

module FedoraMigrate
  class StatusTrackingDatastreamMover < DatastreamMover
    DIGEST_CLASS = Digest::SHA2
    
    def migrate
      ds_name = source.dsid
      source_class = source.digital_object.models.find {|m| /afmodel/ =~ m}.scan(/afmodel:(.+)$/).flatten.last rescue source.class.name
      status = MigrationStatus.create source_class: source_class, f3_pid: source.pid, f4_pid: target.id.split(/\//).first, datastream: ds_name, status: 'migrate'
      begin
        super
        checksums = {
          source: generate_checksum { source.content },
          target: generate_checksum { target.content }
        }
        success = xml? ? EquivalentXml.equivalent?(source.content,target.content) : checksums[:source] == checksums[:target]
        log_message = success ? nil : (xml? ? 'XML fails equivalency test' : 'Checksums do not match')
        status.update_attributes checksum: checksums[:target], status: (success ? 'completed' : 'failed'), log: log_message
      rescue Exception => e
        status.update_attributes status: 'failed', log: e.message
      ensure
        status.save
      end
    end
    
    private
    def generate_checksum
      (DIGEST_CLASS.new << yield).hexdigest
    end
    
    def xml?
      !!(source.mimeType =~ %r{[/+]xml$})
    end
  end
end
