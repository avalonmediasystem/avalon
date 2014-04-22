ActiveFedora::Base.class_eval do
  has_metadata name: 'DC', type: DublinCoreDocument
end
