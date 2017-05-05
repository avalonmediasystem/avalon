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

require 'ostruct'

module FedoraMigrate
  module MediaObject
    class ObjectMover < ReassignIdObjectMover
      DESC_METADATA_DATASTREAM = "descMetadata".freeze
      WORKFLOW_DATASTREAM = "workflow".freeze
      DISPLAY_METADATA_DATASTREAM = "displayMetadata".freeze

      def migrate_datastreams
        migrate_dublin_core
        migrate_relationships
        migrate_permissions
        migrate_desc_metadata #Need to do this after target is saved
        migrate_workflow
        migrate_display_metadata
        migrate_permalink
        # migrate_dates #skip because it doesn't do anything for us
        save
        # super
      end

      def migrate_dublin_core
        return unless source.datastreams.keys.include?('DC')
        mover = FedoraMigrate::MediaObject::DublinCoreDatastreamMover.new(source.datastreams['DC'], target)
        mover.migrate
        # report.dc = mover.migrate
      end

      def migrate_desc_metadata
        return unless source.datastreams.keys.include?(DESC_METADATA_DATASTREAM)
        # Manually set ebucore:filename before the file gets persisted
        target.attached_files[DESC_METADATA_DATASTREAM].original_name = "#{DESC_METADATA_DATASTREAM}.xml"
        mover = FedoraMigrate::StatusTrackingDatastreamMover.new(source.datastreams[DESC_METADATA_DATASTREAM], target.attached_files[DESC_METADATA_DATASTREAM], options)
        #FIXME change MODS recordIdentifier to be new fedora noid id
        report.content_datastreams << ContentDatastreamReport.new(target.attached_files[DESC_METADATA_DATASTREAM], mover.migrate)
      end

      def migrate_workflow
        return unless source.datastreams.keys.include?(WORKFLOW_DATASTREAM)
        # Manually set ebucore:filename before the file gets persisted
        target.attached_files[WORKFLOW_DATASTREAM].original_name = "#{WORKFLOW_DATASTREAM}.xml"
        FedoraMigrate::StatusTrackingDatastreamMover.new(source.datastreams[WORKFLOW_DATASTREAM], target.workflow).migrate
      end

      def migrate_display_metadata
        return unless source.datastreams.keys.include?(DISPLAY_METADATA_DATASTREAM)
        FedoraMigrate::MediaObject::DisplayMetadataDatastreamMover.new(source.datastreams[DISPLAY_METADATA_DATASTREAM], target).migrate
      end

      def second_pass
        @report = OpenStruct.new(options[:report]) if options[:report].present?
        mover = FedoraMigrate::MediaObject::MasterFileAggregationMover.new(source, target)
        report.master_file_order = mover.migrate
        report
      end
    end
  end
end
