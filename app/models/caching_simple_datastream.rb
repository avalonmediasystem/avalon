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

class CachingSimpleDatastream
  class FieldError < Exception; end
  
  class FieldCollector
    attr :fields
    def field(name, type)
      @fields ||= {}
      fields[name] = type
    end
  end

  def self.create(klass)
    cache_class = Class.new(ActiveFedora::SimpleDatastream) do
      class_attribute :owner_class
      
      def self.defined_attributes(ds)
        @defined_attributes ||= {}
        if @defined_attributes[ds].nil?
          fc = FieldCollector.new
          self.owner_class.ds_specs[ds][:block].call(fc)
          @defined_attributes[ds] = fc.fields
        end
        @defined_attributes[ds]
      end
      
      def self.type(field)
        field_def = self.owner_class.defined_attributes[field.to_s]
        raise FieldError, "Unknown field `#{field}` for #{self.owner_class.name}" if field_def.nil?
        self.defined_attributes(field_def.dsid)[field.to_sym]
      end
      
      def primary_solr_name(field)
        ActiveFedora::SolrService.solr_name(field, type: self.type(field))
      end
      
      def type(field)
        self.class.type(field)
      end
    end
    cache_class.owner_class = klass
    cache_class
  end
end
