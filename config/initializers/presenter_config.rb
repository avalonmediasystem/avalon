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
                        height: nil
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
			read_groups: [],
                        read_users: [],
			edit_groups: [],
			edit_users: [],
                        supplemental_files_json: nil,
                        contributor: [],
                        publisher: [],
                        temporal_subject: [],
                        geographic_subject: [],
                        language: [],
                        terms_of_use: nil,
                        physical_description: [],
                        related_item_url: [],
                        note: [],
                        other_identifier: [],
                        rights_statement: nil,
                        table_of_contents: [],
                        bibliographic_id: nil,
                        comment: [],
                        date_issued: nil
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
    end

    sp.config Derivative do
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
end
