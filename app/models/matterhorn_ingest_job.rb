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

class MatterhornIngestJob < Struct.new(:args)
  def perform
    if args[:url].is_a? Hash
      multipleFileIngest
    else
      Rubyhorn.client.addMediaPackageWithUrl(args)
    end
  end

  def multipleFileIngest
    #Create empty media package xml document
    mp = Rubyhorn.client.createMediaPackage

    #Next line associates workflow title to avalon via masterfile pid
    dc = Nokogiri::XML('<dublincore xmlns="http://www.opencastproject.org/xsd/1.0/dublincore/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dcterms:title>' + args[:title] + '</dcterms:title></dublincore>')
    mp = Rubyhorn.client.addDCCatalog({'mediaPackage' => mp.to_xml, 'dublinCore' => dc.to_xml, 'flavor' => 'dublincore/episode'})

    #Add quality levels - repeated for each supplied file url
    args[:url].each_pair do |quality, url|
      mp = Rubyhorn.client.addTrack({'mediaPackage' => mp.to_xml, 'url' => url, 'flavor' => args[:flavor]})
      #Rewrite track to include quality tag
      #Get the empty tags element under the newly added track
      tags = mp.xpath('//xmlns:track/xmlns:tags[not(node())]', 'xmlns' => 'http://mediapackage.opencastproject.org').first
      qualityTag = Nokogiri::XML::Node.new 'tag', mp
      qualityTag.content = quality
      tags.add_child qualityTag
    end

    #Finally ingest the media package
    Rubyhorn.client.ingest({"workflow" => args[:workflow], "mediaPackage" => mp.to_xml})
  end

  def error(job, exception)
    master_file = MasterFile.find(job.payload_object.args[:title])
    # add message here to update master file
    master_file.status_code = 'FAILED'
    master_file.error = exception.message
    master_file.save
  end

end
