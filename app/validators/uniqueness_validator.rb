class UniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless options[:solr_name].present? 
      raise ArgumentError, "UniquenessValidator was not passed :solr_name. Example: validates :uniqueness => { :solr_name => 'name_t' }"
    end

    if ! record.persisted? && ! value.empty? && record.class.where( options[:solr_name] => value ).to_a.count > 0
      record.errors.add attribute, 'Must be unique'
    end
  end
end