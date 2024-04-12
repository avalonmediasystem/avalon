# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

class SpeedyAF::Proxy::MediaObject < SpeedyAF::Base
  SINGULAR_FIELDS = [:title, :statement_of_responsibility, :date_created, :date_issued, :copyright_date, :abstract, :terms_of_use, :rights_statement]
  HASH_FIELDS = [:note, :other_identifier, :related_item_url]

  # Override to handle section_id specially
  def initialize(solr_document, instance_defaults = {})
    instance_defaults ||= {}
    @model = SpeedyAF::Base.model_for(solr_document)
    @attrs = self.class.defaults.merge(instance_defaults)
    solr_document.each_pair do |k, v|
      attr_name, value = parse_solr_field(k, v)
      @attrs[attr_name.to_sym] = value
    end
    # Handle this case here until a better fix can be found for multiple solr fields which don't have a model property
    @attrs[:section_id] = solr_document["section_id_ssim"]
    @attrs[:hidden?] = solr_document["hidden_bsi"]
    @attrs[:read_groups] = solr_document["read_access_group_ssim"] || []
    @attrs[:edit_groups] = solr_document["edit_access_group_ssim"] || []
    @attrs[:read_users] = solr_document["read_access_person_ssim"] || []
    @attrs[:edit_users] = solr_document["edit_access_person_ssim"] || []

    # TODO Need to convert hidden_bsi into discover_groups?
    SINGULAR_FIELDS.each do |field_name|
      @attrs[field_name] = Array(@attrs[field_name]).first
    end

    HASH_FIELDS.each do |field_name|
      @attrs[field_name].collect! { |hf| JSON.parse(hf, :symbolize_names => true) }
    end
    # Convert empty strings to nil
    @attrs.transform_values! { |value| value == "" ? nil : value }
  end

  def to_model
    self
  end

  def persisted?
    id.present?
  end

  def model_name
    ActiveModel::Name.new(MediaObject)
  end

  def to_param
    id
  end

  def to_key
    [id]
  end

  # @return [SupplementalFile]
  def supplemental_files(tag: '*')
    return [] if supplemental_files_json.blank?
    files = JSON.parse(supplemental_files_json).collect { |file_gid| GlobalID::Locator.locate(file_gid) }
    case tag
    when '*'
      files
    when nil
      files.select { |file| file.tags.empty? }
    else
      files.select { |file| Array(tag).all? { |t| file.tags.include?(t) } }
    end
  end

  def master_file_ids
    if real?
      real_object.master_file_ids
    elsif section_id.nil? # No master files or not indexed yet
      ActiveFedora::Base.logger.warn("Reifying MediaObject because master_files not indexed")
      real_object.master_file_ids
    else
      section_id
    end
  end
  alias_method :ordered_master_file_ids, :master_file_ids

  def master_files
    # NOTE: Defaults are set on returned SpeedyAF::Base objects if field isn't present in the solr doc.
    # This is important otherwise speedy_af will reify from fedora when trying to access this field.
    # When adding a new property to the master file model that will be used in the interface,
    # add it to the default below to avoid reifying for master files lacking a value for the property.
    @master_files ||= SpeedyAF::Proxy::MasterFile.where("isPartOf_ssim:#{id}",
                                                        order: -> { master_file_ids },
                                                        load_reflections: true)
  end
  alias_method :ordered_master_files, :master_files

  def collection
    @collection ||= SpeedyAF::Proxy::Admin::Collection.find(collection_id)
  end

  def lending_period
    attrs[:lending_period].presence || collection&.default_lending_period
  end

  def format
    # TODO figure out how to memoize this
    mime_types = master_files.reject { |mf| mf.file_location.blank? }.collect do |mf|
      Rack::Mime.mime_type(File.extname(mf.file_location))
    end.uniq
    mime_types.empty? ? nil : mime_types
  end

  # Copied from Hydra-Access-Controls
  def visibility
    if read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    elsif read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    else
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end
  end

  def represented_visibility
    [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED,
     Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
  end

  def leases(scope=:all)
    governing_policies.select { |gp| gp.is_a?(SpeedyAF::Proxy::Lease) and (scope == :all or gp.lease_type == scope) }
  end

  def governing_policies
    @governing_policies ||= Array(attrs[:isGovernedBy]).collect { |id| SpeedyAF::Base.find(id) }
  end

  def language
    attrs[:language_code].present? ? attrs[:language_code].map { |code| { code: code, text: LanguageTerm.find(code).text } } : []
  end

  def sections_with_files(tag: '*')
    master_files.select { |master_file| master_file.supplemental_files(tag: tag).present? }.map(&:id)
  end

  def permalink_with_query(query_vars = {})
    val = permalink
    if val && query_vars.present?
      val = "#{val}?#{query_vars.to_query}"
    end
    val ? val.to_s : nil
  end

  protected

  # Overrides from SpeedyAF::Base
  def parse_solr_field(k, v)
    # :nocov:
    transforms = {
      'dt' => ->(m) { Time.parse(m) },
      'b' => ->(m) { m },
      'db' => ->(m) { m.to_f },
      'f' => ->(m) { m.to_f },
      'i' => ->(m) { m.to_i },
      'l' => ->(m) { m.to_i },
      nil => ->(m) { m }
    }
    # :nocov:
    attr_name, type, _stored, _indexed, multi = k.scan(/^(.+)_(.+)(s)(i?)(m?)$/).first
    return [k, v] if attr_name.nil?
    value = Array(v).map { |m| transforms.fetch(type, transforms[nil]).call(m) }
    value = value.first if multi.blank? || singular?(attr_name)
    [attr_name, value]
  end

  def singular?(attr_name)
    prop = @model.properties[attr_name]
    (prop.present? && prop.respond_to?(:multiple?) && !prop.multiple?) || belongs_to_reflections.values.collect(&:predicate_for_solr).include?(attr_name)
  end
end
