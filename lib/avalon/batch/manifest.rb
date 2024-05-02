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

require 'roo'

module Avalon
  module Batch
    class Manifest
      include Enumerable
      extend Forwardable

      EXTENSIONS = ['csv','xls','xlsx','ods']
      FILE_FIELDS = [:file,:label,:offset,:skip_transcoding,:absolute_location,:date_digitized, :caption_file, :caption_label, :caption_language, 
                     :transcript_file, :transcript_label, :machine_generated]
      SKIP_FIELDS = [:collection]

      def_delegators :@entries, :each
      attr_reader :spreadsheet, :file, :name, :email, :entries, :package

      class << self
        def concrete_class=(value)
          raise ArgumentError, "#{value} is not a #{self.name}" unless self.descendants.include?(value)
          @concrete_class = value
        end

        def concrete_class
          @concrete_class ||= FileManifest
        end

        def is_spreadsheet?(file)
          EXTENSIONS.include?(file.split(/\./).last.downcase)
        end

        def load(*args)
          concrete_class.new(*args)
        end

        def locate(root)
          concrete_class.locate(root)
        end
      end

      def initialize(file, package)
        raise "#{self.class.name} is an abstract class. Please set #concrete_class and use #load()" unless self.respond_to?(:start!)
        @file = file
        @package = package
        load!
      end

      def load!
        @entries = []
        begin
          @spreadsheet = Roo::Spreadsheet.open(FileLocator.new(file).location)
          @name = @spreadsheet.row(@spreadsheet.first_row)[0]
          @email = @spreadsheet.row(@spreadsheet.first_row)[1]

          header_row = @spreadsheet.row(@spreadsheet.first_row + 1)

          @field_names = header_row.collect { |field|
            field.to_s.downcase.gsub(/\s/,'_').strip.to_sym
          }
          create_entries!
        rescue Exception => err
          error! "Invalid manifest file: #{err.message}"
        end
      end

      def error?
        result = self.class.error?(@file)
        load! unless result
        result
      end

      def processing?
        self.class.processing?(@file)
      end

      def processed?
        self.class.processed?(@file)
      end

      def errors
        @errors ||= []
      end

      def delete
        self.class.delete(@file)
      end

      private
      def true?(value)
        not (value.to_s =~ /^(y(es)?|t(rue)?)$/i).nil?
      end

      def supplementing_files(field, content, values, i)
        if field.to_s.include?('file')
          @key = case field
                 when /caption.*/
                   @caption_count += 1
                   "caption_#{@caption_count}".to_sym
                 when /transcript.*/
                   @transcript_count += 1
                   "transcript_#{@transcript_count}".to_sym
                 end
          content.last[@key] = {}
          # Set file path to caption/transcript file
          content.last[@key][field] = path_to(values[i])
        end
        # Set caption/transcript metadata fields
        content.last[@key][field] ||= values[i]
      end

      def create_entries!
        first = @spreadsheet.first_row + 2
        last = @spreadsheet.last_row
        first.upto(last) do |index|
          opts = {
            :publish => false,
            :hidden  => false
          }

          values = @spreadsheet.row(index).collect do |val|
            (val.is_a?(Float) and (val == val.to_i)) ? val.to_i.to_s : val.to_s
          end
          content=[]

          fields = Hash.new { |h,k| h[k] = [] }
          @caption_count = 0
          @transcript_count = 0
          @field_names.each_with_index do |f,i|
            unless f.blank? || SKIP_FIELDS.include?(f) || values[i].blank?
              if FILE_FIELDS.include?(f)
                content << {} if f == :file
                if ['caption', 'transcript', 'machine_generated'].any? { |type| f.to_s.include?(type) }
                  supplementing_files(f, content, values, i)
                  next
                end
                content.last[f] = f == :skip_transcoding ? true?(values[i]) : values[i]
              else
                fields[f] << values[i]
              end
            end
          end

          opts.keys.each { |opt|
            val = Array(fields.delete(opt)).first.to_s
            if opts[opt].is_a?(TrueClass) or opts[opt].is_a?(FalseClass)
              opts[opt] = true?(val)
            else
              opts[opt] = val
            end
          }
          files = content.each { |file| file[:file] = path_to(file[:file]) }
          entries << Entry.new(fields.select { |f| !FILE_FIELDS.include?(f) }, files, opts, index, self)
        end
      end
    end
  end
end
