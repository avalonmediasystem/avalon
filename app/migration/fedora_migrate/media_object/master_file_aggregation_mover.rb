# Copyright 2011-2017, The Trustees of Indiana University and Northwestern
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
  module MediaObject
    class MasterFileAggregationMover < ObjectMover
      def migrate
        return false unless target.migrated_from.present?
        master_files = ::MasterFile.where(isPartOf_ssim: target.id)
        if source.datastreams.has_key?('sectionsMetadata')
          sections_md = Nokogiri::XML(source.datastreams['sectionsMetadata'].content)
          old_pid_order = sections_md.xpath('fields/section_pid').collect(&:text)
          target.ordered_master_files = master_files.sort do |a,b|
            old_pid_order.index(pid_from_obj(a)) <=> old_pid_order.index(pid_from_obj(b))
          end
        else
          target.ordered_master_files = master_files
        end
        target.save
        master_files.collect(&:id)
      end

      private
        def pid_from_obj(obj)
          obj.migrated_from.first.rdf_subject.to_s.split('/').last
        end
    end
  end
end
