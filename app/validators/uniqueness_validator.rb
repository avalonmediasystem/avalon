class UniquenessValidator < ActiveModel::EachValidator
  def initialize(options)
    unless options[:solr_name].present?
      raise ArgumentError, "UniquenessValidator was not passed :solr_name. Example: validates :uniqueness => { :solr_name => 'name_t' }"
    end
    @solr_field = options[:solr_name]
    super
  end
  def validate_each(record, attribute, value)
    klass = record.class
    existing_doc = find_doc(klass, value)
    
    if ! existing_doc.nil? && existing_doc.pid != record.pid
      record.errors.add attribute, :taken, value: value
    end
  end
  def find_doc(klass, value)
    klass.where(@solr_field => value).first
  end
end 
