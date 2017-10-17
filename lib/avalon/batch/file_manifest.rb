module Avalon
  module Batch
    class FileManifest < Manifest
      class << self
        def locate(root)
          possibles = Dir[File.join(root, "**/*.{#{Manifest::EXTENSIONS.join(',')}}")]
          possibles.reject do |file|
            File.basename(file) =~ /^~\$/ or self.error?(file) or self.processing?(file) or self.processed?(file)
          end
        end

        def error?(file)
          if File.file?("#{file}.error")
            if File.mtime(file) > File.mtime("#{file}.error")
              File.unlink("#{file}.error")
              return false
            else
              return true
            end
          end
          return false
        end

        def processing?(file)
          File.file?("#{file}.processing")
        end

        def processed?(file)
          File.file?("#{file}.processed")
        end

        def delete(file)
          FileUtils.rm(file, force: true)
        end
      end

      def start!
        File.open("#{@file}.processing",'w') { |f| f.puts Time.now.xmlschema }
      end

      def error! msg=nil
        File.open("#{@file}.error",'a') do |f|
          if msg.nil?
            entries.each do |entry|
              if entry.errors.count > 0
                f.puts "Row #{entry.row}:"
                entry.errors.messages.each { |k,m| f.puts %{  #{m.join("\n  ")}} }
              end
            end
          else
            f.puts msg
          end
        end
        rollback! if processing?
      end

      def rollback!
        File.unlink("#{@file}.processing")
      end

      def commit!
        File.open("#{@file}.processed",'w') { |f| f.puts Time.now.xmlschema }
        rollback! if processing?
      end

      def path_to(f)
        File.join(File.dirname(@file),f)
      end

      def dir
        File.dirname(@file)
      end

      def retrieve(f)
        File.open(f)
      end
    end
  end
end
