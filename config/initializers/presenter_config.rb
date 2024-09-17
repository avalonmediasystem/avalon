Rails.application.config.to_prepare do
  SpeedyAF::Base.tap do |sp|
    sp.config MasterFile do
      self.defaults = {
                        permalink: nil,
                        title: nil,
                        encoder_classname: nil,
                        workflow_id: nil,
                        comment: [],
                        supplemental_files_json: nil,
                        width: nil,
                        height: nil,
                        physical_description: nil,
                        file_size: nil,
                        date_digitized: nil,
                        file_checksum: nil,
                        identifier: [],
                        percent_complete: nil,
                        status_code: nil,
                        operation: nil,
                        error: nil
                      }
      include MasterFileIntercom
      include MasterFileBehavior
      include Rails.application.routes.url_helpers
    end

    sp.config MediaObject do
      self.defaults = {
                        permalink: nil,
                        abstract: nil,
                        genre: [],
                        subject: [],
                        statement_of_responsibility: nil,
                        avalon_publisher: nil,
                        creator: [],
                        discover_groups: [],
                        supplemental_files_json: nil,
                        contributor: [],
                        publisher: [],
                        temporal_subject: [],
                        topical_subject: [],
                        geographic_subject: [],
                        language: [],
                        language_code: [],
                        terms_of_use: nil,
                        physical_description: [],
                        related_item_url: [],
                        note: [],
                        other_identifier: [],
                        rights_statement: nil,
                        table_of_contents: [],
                        bibliographic_id: nil,
                        comment: [],
                        date_issued: nil,
                        avalon_uploader: nil,
                        identifier: [],
                        alternative_title: [],
                        translated_title: [],
                        uniform_title: [],
                        resource_type: [],
                        record_identifier: [],
                        series: [],
                        format: []
                      }
      include VirtualGroups
      include MediaObjectIntercom
      include MediaObjectBehavior
      include Rails.application.routes.url_helpers
    end

    sp.config Admin::Collection do
      self.defaults = {
                        cdl_enabled: nil
                      }
      include AdminCollectionBehavior
    end

    sp.config Derivative do
      self.defaults = {
                        track_id: nil,
                        mime_type: nil,
                        hls_track_id: nil,
                        video_bitrate: nil,
                        video_codec: nil,
                        audio_bitrate: nil,
                        audio_codec: nil
                      }
      include DerivativeIntercom
      include DerivativeBehavior
    end

    sp.config Lease do
      self.defaults = { lease_type: nil }
    end

    sp.config StructuralMetadata do
      def ng_xml
	@ng_xml ||= Nokogiri::XML(content)
      end

      def xpath(*args)
	ng_xml.xpath(*args)
      end
    end
  end

  SpeedyAF::Base.class_eval do
    # Override to skip clearing attrs when reifying to avoid breaking overridden methods which read from attrs
    def real_object
      if @real_object.nil?
	@real_object = model.find(id)
	# @attrs.clear
      end
      @real_object
    end
  end

  # Reduce from 10_000_000 to reduce solr QTimes from triple digits to single digits
  SpeedyAF::Base::SOLR_ALL = 100_000
end
