baseparts = 2 + [(Noid::Rails.config.template.gsub(/\.[rsz]/, '').length.to_f / 2).ceil, 4].min
baseurl = "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}"
ActiveFedora::Base.translate_uri_to_id = lambda do |uri|
                                           uri.to_s.sub(baseurl, '').split('/', baseparts).last
                                         end
ActiveFedora::Base.translate_id_to_uri = lambda do |id|
                                           "#{baseurl}/#{Noid::Rails.treeify(id)}"
                                         end
ActiveFedora::Base.logger = Rails.logger

require 'solrizer'
