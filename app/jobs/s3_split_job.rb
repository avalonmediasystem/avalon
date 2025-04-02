# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

class S3SplitJob < ActiveJob::Base
  queue_as :s3_split
  def perform(file)
    ffmpeg = Settings.ffmpeg.path
    input = FileLocator.new(file).location
    s3obj = FileLocator::S3File.new(file).object
    bucket = s3obj.bucket
    path = File.dirname(s3obj.key)
    base = File.basename(s3obj.key,'.*')
    Dir.mktmpdir do |dir|
      cmd = [
        ffmpeg,
        '-i', input,
        '-codec','copy',
        '-map','0',
        '-bsf:v','h264_mp4toannexb',
        '-f','segment',
        '-segment_format', 'mpegts',
        '-segment_list', File.join(dir, "#{base}.m3u8"),
        '-segment_time', '10', File.join(dir, "#{base}-%03d.ts")
      ]
      if Kernel.system(*cmd)
        segment_files = Dir[File.join(dir,'*')]
        segment_files.each do |seg|
          File.open(seg,'r') { |io| bucket.put_object(key: File.join(path,'hls',File.basename(seg)), body: io) }
        end
      end
    end
  end
end
