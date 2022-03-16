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
  module MasterFile
    class ObjectMover < ReassignIdObjectMover
      DESC_METADATA_DATASTREAM = "descMetadata".freeze
      POSTER_DATASTREAM = "poster".freeze
      THUMBNAIL_DATASTREAM = "thumbnail".freeze
      STRUCTURAL_METADATA_DATASTREAM = "structuralMetadata".freeze
      CAPTIONS_DATASTREAM = "captions".freeze
      MASTERFILE_DATASTREAM = "masterFile".freeze
      MH_METADATA_DATASTREAM = "mhMetadata".freeze

      def migrate
        #find mediaobject pid to see if it's already failed
        rels_rdf = RDF::Graph.new { |g| g.from_rdfxml(source.datastreams["RELS-EXT"].content) }
        media_object_pid = rels_rdf.statements.find {|s| s.predicate == ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf }.object.to_s.split('/').last
        mo_status = MigrationStatus.where(f3_pid: media_object_pid).first.status
        raise FedoraMigrate::Errors::MigrationError, "Parent media object (#{media_object_pid}) failed to migrate" if mo_status == "failed"
        super
      end

      def migrate_datastreams
        migrate_dublin_core
        migrate_desc_metadata
        migrate_transcoding_metadata
        migrate_title
        migrate_file_location
        save   # save before creating contained files
        migrate_poster_and_thumbnail
        migrate_structural_metadata
        migrate_captions
        save
        migrate_relationships
        migrate_permalink
        target.ldp_source.save #Because save isn't persisting the isPartOf relationship
        # super
      end

      def migrate_desc_metadata
        return unless source.datastreams.keys.include?(DESC_METADATA_DATASTREAM)
        mover = FedoraMigrate::MasterFile::DescMetadataDatastreamMover.new(source.datastreams[DESC_METADATA_DATASTREAM], target)
        mover.migrate
        # report.descMetadata = mover.migrate
      end

      def migrate_transcoding_metadata
        return unless source.datastreams.keys.include?(MH_METADATA_DATASTREAM)
        mover = FedoraMigrate::MasterFile::MhMetadataDatastreamMover.new(source.datastreams[MH_METADATA_DATASTREAM], target)
        result = mover.migrate
        if target.workflow_name.nil? || (not ::MasterFile::WORKFLOWS.include?(target.workflow_name))
          target.workflow_name = target.file_format == 'Sound' ? 'fullaudio' : 'avalon'
        end
        result
      end

      def migrate_poster_and_thumbnail
        migrate_content_datastream(POSTER_DATASTREAM, target.poster, "#{POSTER_DATASTREAM}.jpg")
        migrate_content_datastream(THUMBNAIL_DATASTREAM, target.thumbnail, "#{THUMBNAIL_DATASTREAM}.jpg")
      end

      def migrate_structural_metadata
        migrate_content_datastream(STRUCTURAL_METADATA_DATASTREAM, target.structuralMetadata, "#{STRUCTURAL_METADATA_DATASTREAM}.xml")
      end

      def migrate_captions
        migrate_content_datastream(CAPTIONS_DATASTREAM, target.captions, source.datastreams[CAPTIONS_DATASTREAM].label.try(:gsub, /"/, '\"'))
      end

      def migrate_file_location
        return unless source.datastreams.keys.include?(MASTERFILE_DATASTREAM)
        target.masterFile = source.datastreams[MASTERFILE_DATASTREAM].content.to_s.force_encoding(Encoding.default_external)
      end

      def migrate_title
        return unless source.label
        target.title = source.label
      end

      private
      def migrate_content_datastream(ds_name, target_file, filename)
        return unless source.datastreams.keys.include?(ds_name)
        # Manually set ebucore:filename before the file gets persisted
        target_file.original_name = filename
        mover = FedoraMigrate::DatastreamMover.new(source.datastreams[ds_name], target_file)
        mover.migrate
        #report.content_datastreams << ContentDatastreamReport.new(target.attached_files[ds_name], mover.migrate)
      end
    end
  end
end
