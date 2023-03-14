# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

module Avalon
  module Batch
    class Package
      include Enumerable
      extend Forwardable

      attr_reader :manifest, :collection
      def_delegators :@manifest, :each, :dir

      def self.locate(root, collection)
        Avalon::Batch::Manifest.locate(root).collect { |f| self.new(f, collection) }
      end

      def initialize(manifest, collection)
        @manifest = Avalon::Batch::Manifest.load(manifest, self)
        @collection = collection
      end

      def title
        File.basename(@manifest.file)
      end

      def user
        @user ||=
          User.where(Devise.authentication_keys.first => @manifest.email).first ||
          User.where(username: @manifest.email).first ||
          User.where(email: @manifest.email).first
        @user
      end

      def file_list
        @manifest.collect { |entry| entry.files }.flatten.collect { |f| @manifest.path_to(f[:file]) }
      end

      def complete?
        file_list.all? { |f| FileLocator.new(f).exist? }
      end

      def each_entry
        @manifest.each_with_index do |entry, index|
          files = entry.files.dup
          files.each { |file| file[:file] = @manifest.path_to(file[:file]) }
          yield(entry.fields, files, entry.opts, entry, index)
        end
      end

      def processing?
        @manifest.processing?
      end

      def processed?
        @manifest.processed?
      end

      def valid?
        @manifest.each { |entry| entry.valid? }
        @manifest.all? { |entry| entry.errors.count == 0 }
      end

      def process!
        @manifest.start!
        begin
          media_objects = @manifest.entries.collect { |entry| entry.process! }
          @manifest.commit!
        rescue Exception
          @manifest.error!
          raise
        end
        media_objects
      end

      def errors
        Hash[@manifest.collect { |entry| [entry.row,entry.errors] }]
      end
    end
  end
end
