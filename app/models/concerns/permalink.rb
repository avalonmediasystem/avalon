# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

module Permalink

  extend ActiveSupport::Concern

  ActiveSupport::Reloader.to_prepare do
    ::Permalink.class_variable_set(:@@generator, @@generator) if @@generator
  end

  class Generator
    include Rails.application.routes.url_helpers
    attr_accessor :proc

    def initialize
      @proc = Proc.new { |obj, target| nil }
    end

    def avalon_url_for(obj)
      case obj
      when MediaObject then media_object_url(obj.id)
      when MasterFile  then id_section_media_object_url(obj.media_object.id, obj.id)
      else raise ArgumentError, "Cannot make permalink for #{obj.class}"
      end
    end

    def permalink_for(obj)
      @proc.call(obj, avalon_url_for(obj))
    end
  end

  @@generator = Generator.new
  def self.permalink_for(obj)
    @@generator.permalink_for(obj)
  end

  included do
    property :permalink, predicate: ::RDF::Vocab::DC.identifier, multiple: false do |index|
      index.as :stored_searchable
    end
  end

  def self.url_for(obj)
    @@generator.avalon_url_for(obj)
  end

  # Permalink.on_generate do |obj|
  #   permalink = (... generate permalink ...)
  #   return permalink
  # end
  def self.on_generate(&block)
    @@generator.proc = block
  end

  def permalink_with_query(query_vars = {})
    val = self.attributes['permalink']
    if val && query_vars.present?
      val = "#{val}?#{query_vars.to_query}"
    end
    val ? val.to_s : nil
  end

  # wrap this method; do not use this method as a callback
  # if it returns false it will skip the rest of the items in the callback chain

  def ensure_permalink!
    updated = false
    begin
      link = self.permalink
      if link.blank?
        link = Permalink.permalink_for(self)
      end

    rescue Exception => e
      link = nil
      logger.error "Permalink.permalink_for() raised an exception for #{self.inspect}: #{e}"
    end
    if link.present? and not (self.permalink == link)
      self.permalink = link
      updated = true
    end
    updated
  end

end
