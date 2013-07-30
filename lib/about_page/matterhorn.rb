# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

module AboutPage
  class Matterhorn < AboutPage::Configuration::Node
    delegate :each_pair, :to_json, :to_xml, :to => :to_h
    validates_each :services do |record, attr, value|
      record.services.each { |s| 
        if s['service_state'].to_s != 'NORMAL'
          record.errors.add s['path'], ": #{s['service_state']} (#{complete_status(s)})"
        end
      }
    end

    def initialize(connection)
      @connection = connection
    end

    def services
      to_h['service']
    end

    def to_h
      @connection.services['services']
    end

    def self.complete_status(service)
      [
        service['active'] ? 'active' : 'inactive',
        service['online'] ? 'online' : 'offline',
        service['maintenance'] ? 'maintenance' : nil
      ].compact.join(', ')
    end
  end
end
