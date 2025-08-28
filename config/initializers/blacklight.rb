require 'blacklight'

Rails.application.config.to_prepare do
  Blacklight::SearchState.class_eval do
    def url_for_document doc, options = {}
      SpeedyAF::Base.for(doc.to_h.with_indifferent_access)
    end
  end
end
