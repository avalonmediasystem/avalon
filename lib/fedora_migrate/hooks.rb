# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

module FedoraMigrate::Hooks
  # Both @source and @target are available, as the Rubydora object and ActiveFedora model, respectively
  def before_object_migration
    if target.class == Admin::Collection
      before_collection_migration(source, target)
    elsif target.class == MediaObject
      before_media_object_migration(source, target)
    elsif target.class == MasterFile
      before_master_file_migration(source, target)
    elsif target.class == Derivative
      before_derivative_migration(source_target)
    elsif target.class == Lease
      before_lease_migration(source, target)
    end
  end

  def before_collection_migration(source, target)
    #FIXME change report to better report collection data
    # descMetadata = Nokogiri::XML(source.datastreams['descMetadata'].content)
    # target.name = descMetadata.xpath('fields/name').text
    # target.unit = descMetadata.xpath('fields/unit').text
    # target.description = descMetadata.xpath('fields/description').text
    # target.dropbox_directory_name = descMetadata.xpath('fields/dropbox_directory_name').text
    # defaultRights = Nokogiri::XML(source.datastreams['defaultRights'].content)
    # defaultRights.remove_namespaces!
    # target.default_read_users = defaultRights.xpath('//access[@type="read"]/machine/person').map(&:text)
    # target.default_read_groups = defaultRights.xpath('//access[@type="read"]/machine/group').map(&:text)
    # target.default_hidden = defaultRights.xpath('//access[@type="discover"]/machine/group[text()="nobody"]').present?

    # dc = Nokogiri::XML(source.datastreams['DC'].content)
    # dc.remove_namespaces!
    # target.identifier += dc.xpath('//identifier').map(&:text)
    # target.identifier += [source.pid]
    #TODO need to do uniq! on target.identifier?

    # #Add units to controlled vocabulary
    # v = Avalon::ControlledVocabulary.vocabulary
    # unless v[:units].include? target.unit
    #  v[:units] |= Array(target.unit)
    #  Avalon::ControlledVocabulary.vocabulary = v
    # end

    # inheritedRights = Nokogiri::XML(source.datastreams['inheritedRights'].content)
    # inheritedRights.remove_namespaces!
    # #This will set both editors and managers
    # target.editors = inheritedRights.xpath('//rightsMetadata/access[@type="edit"]/machine/person').map(&:text)
    # target.depositors = inheritedRights.xpath('//rightsMetadata/access[@type="read"]/machine/person').map(&:text)
  end

  def before_media_object_migration(source, target)
    #byebug
    relsExt = Nokogiri::XML(source.datastreams['RELS-EXT'].content)
    target.collection = Admin::Collection.find(relsExt.xpath("//ns2:isMemberOfCollection/@rdf:resource").first.value.split('/').last)
  end

  def before_master_file_migration(source, target)
    # For transform mhMetadata datastream into MasterFile properties
    mhMetadata = Nokogiri::XML(source.datastreams['mhMetadata'].content)
    target.workflow_name = mhMetadata.xpath('fields/workflow_name').text
    target.percent_complete = mhMetadata.xpath('fields/percent_complete').text
    target.percent_succeeded = mhMetadata.xpath('fields/percent_succeeded').text
    target.percent_failed = mhMetadata.xpath('fields/percent_failed').text
    target.operation = mhMetadata.xpath('fields/operation').text
    target.workflow_id = mhMetadata.xpath('fields/workflow_id').text
    target.status_code = mhMetadata.xpath('fields/status_code').text
  end

  def before_derivative_migration(source, target)
  end

  def before_lease_migration(source, target)
  end

  def after_object_migration
    # additional actions as needed
  end
end
