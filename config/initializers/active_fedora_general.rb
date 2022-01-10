baseparts = 2 + [(Noid::Rails.config.template.gsub(/\.[rsz]/, '').length.to_f / 2).ceil, 4].min
baseurl = "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}"
ActiveFedora::Base.translate_uri_to_id = lambda do |uri|
                                           uri.to_s.sub(baseurl, '').split('/', baseparts).last
                                         end
ActiveFedora::Base.translate_id_to_uri = lambda do |id|
                                           "#{baseurl}/#{Noid::Rails.treeify(id)}"
                                         end
ActiveFedora::Base.logger = Rails.logger

# Monkey-patch to short circuit ActiveModel::Dirty which attempts to load the whole master files ordered list when calling nodes_will_change!
# This leads to a stack level too deep exception when attempting to delete a master file from a media object on the manage files step.
# See https://github.com/samvera/active_fedora/pull/1312/commits/7c8bbbefdacefd655a2ca653f5950c991e1dc999#diff-28356c4daa0d55cbaf97e4269869f510R100-R103
ActiveFedora::Aggregation::ListSource.class_eval do
  def attribute_will_change!(attr)
    return super unless attr == 'nodes'
    attributes_changed_by_setter[:nodes] = true
  end
end

# Override to avoid deprecation warning.  Remove this monkey-patch whenever Avalon upgrades to a version of ActiveFedora which has this fix.
ActiveFedora::File.class_eval do
  def ldp_headers
    headers = { 'Content-Type'.freeze => mime_type, 'Content-Length'.freeze => content.size.to_s }
    headers['Content-Disposition'.freeze] = "attachment; filename=\"#{URI::DEFAULT_PARSER.escape(@original_name)}\"" if @original_name
    headers
  end
end

# Override to avoid deprecation warning.  Remove this monkey-patch whenever Avalon upgrades to a version of LDP which has this fix.
Ldp::Response.class_eval do
  def content_disposition_filename
    filename = content_disposition_attributes['filename']
    ::RDF::URI.decode(filename) if filename
  end
end
