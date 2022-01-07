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

module Avalon
  module Batch
    class S3Manifest < Manifest
      class << self
        def locate(root)
          root_object = FileLocator::S3File.new(root).object
          bucket = root_object.bucket
          manifests = bucket.objects(prefix: root_object.key).select do |o|
            is_spreadsheet?(o.key) && status(bucket.object(o.key)).blank?
          end
          manifests.collect { |o| "s3://#{o.bucket_name}/#{o.key}" }
        end

        def status(file)
          case file
          when Aws::S3::Object then file.metadata['batch-status']
          else FileLocator::S3File.new(file.to_s).object.metadata['batch-status']
          end
        end

        def status?(file, status)
           status(file) == status
        end
        def error?(file)      ; status?(file, 'error')      ; end
        def processing?(file) ; status?(file, 'processing') ; end
        def processed?(file)  ; status?(file, 'processed')  ; end

        def status!(file, status)
          obj = FileLocator::S3File.new(file).object
          obj.copy_to(
            bucket: obj.bucket_name,
            key: obj.key,
            content_type: obj.content_type,
            metadata: obj.metadata.merge('batch-status'=>status),
            metadata_directive: 'REPLACE'
          )
        end

        def delete(file)
          FileLocator::S3File.new(file).object.delete
        end
      end

      def initialize(*args)
        super
      end

      def commit!   ; self.class.status!(file, 'processed')  ; end
      def start!    ; self.class.status!(file, 'processing') ; end

      def error!(msg=nil)
        begin
          error_obj = FileLocator::S3File.new("#{file}.error").object
          io = StringIO.new
          if msg.nil?
            entries.each do |entry|
              if entry.errors.count > 0
                io.puts "Row #{entry.row}:"
                entry.errors.messages.each { |k,m| io.puts %{  #{m.join("\n  ")}} }
              end
            end
          else
            io.puts msg
          end
          io.rewind
          error_obj.put(body: io)
        ensure
          self.class.status!(file, 'error')
        end
      end

      def path_to(f)
        FileLocator.new(file).uri.join(f).to_s
      end

      def dir
        FileLocator.new(file).uri.to_s
      end

      def retrieve(f)
        FileLocator::S3File.new(f).object.get.body
      end
    end
  end
end
