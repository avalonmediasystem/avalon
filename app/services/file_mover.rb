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

class FileMover
  class << self
    def move(source, dest, method: nil)
      new(source, dest, method: method).move
    end
  end

  def initialize(source, dest, method: nil)
    @source = source
    @dest = dest
    @method = method
  end

  def move
    send(method, @source, @dest)
  end

  def method
    @method || "#{@source.uri.scheme}_to_#{@dest.uri.scheme}".to_sym
  end

  private

  def s3_to_s3(source, dest)
    source_object = FileLocator::S3File.new(source.source).object
    dest_object = FileLocator::S3File.new(dest.source).object
    if dest_object.copy_from(source_object, multipart_copy: source_object.size > 15.megabytes)
      source_object.delete if FileLocator.new(dest.source).exists?
    end
  end

  def s3_to_file(source, dest)
    source_object = FileLocator::S3File.new(source.source).object
    FileUtils.mkdir_p File.dirname(dest.uri.path) unless File.exist? File.dirname(dest.uri.path)
    if source_object.download_file(dest.uri.path)
      source_object.delete
    end
  end

  def file_to_s3(source, dest)
    dest_object = FileLocator::S3File.new(dest.source).object
    if dest_object.upload_file(source.uri.path)
      FileUtils.rm(source.uri.path)
    end
  end

  def file_to_file(source, dest)
    FileUtils.mkdir_p File.dirname(dest.location) unless File.exist? File.dirname(dest.location)
    FileUtils.mv source.location, dest.location
  end
end