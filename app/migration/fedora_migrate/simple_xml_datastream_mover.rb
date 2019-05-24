# Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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

module FedoraMigrate
  class SimpleXmlDatastreamMover < FedoraMigrate::Mover

    attr_accessor :content

    def post_initialize
      @content = xml_from_content
    end

    def fields_to_copy
      []
    end

    def migrate
      fields_to_copy.each { |field| copy_field(field) }
      super
    end

    private
    def copy_field(source_field, target_field=nil, multiple=false, &block)
      target_field = source_field if target_field.nil?
      target.send("#{source_field}=".to_sym, present_or_nil(fetch_field(target_field.to_s, multiple), &block))
    end

    def fetch_field(name, multiple=false)
      multiple ? @content.xpath("fields/#{name}").map(&:text) : @content.xpath("fields/#{name}").text
    end

    def present_or_nil(value)
      return nil unless value.present?
      block_given? ? yield(value) : value
    end

    def xml_from_content
      Nokogiri::XML(source.content)
    end
  end
end
