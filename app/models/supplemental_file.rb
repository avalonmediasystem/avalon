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

class SupplementalFile < ApplicationRecord
  has_one_attached :file

  FILE_TYPES = { caption: ['text/vtt', 'text/srt'], transcript: ['text/vtt', 'text/srt', 'text/plain', 'application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'] }

  # TODO: the empty tag should represent a generic supplemental file
  validates :tags, array_inclusion: ['transcript', 'caption', 'machine_generated', '', nil]
  validates :language, inclusion: { in: LanguageTerm.map.keys }
  validate  :validate_caption_file, if: :caption?
  validate  :validate_transcript_file, if: :transcript?

  serialize :tags, Array 

  def validate_caption_file
    errors.add(:file_type, "Uploaded file is not a recognized captions file. Caption must be a VTT or SRT file.") unless FILE_TYPES[:caption].include? file.content_type
  end

  def validate_transcript_file
    errors.add(:file_type, "Uploaded file is not a recognized transcript file. Transcript must be a VTT, SRT, DOCX, PDF, or TXT file.") unless FILE_TYPES[:transcript].include? file.content_type 
  end

  def attach_file(new_file)
    file.attach(new_file)
    extension = File.extname(new_file.original_filename)
    self.file.content_type = Mime::Type.lookup_by_extension(extension.slice(1..-1)).to_s if extension == '.srt'
    self.label = file.filename.to_s if label.blank?
    self.language = tags.include?('caption') ? Settings.caption_default.language : 'eng'
  end

  def mime_type
    file.content_type
  end

  def caption?
    tags.include?('caption')
  end

  def transcript?
    tags.include?('transcript')
  end

  def machine_generated?
    tags.include?('machine_generated')
  end

  # Adapted from https://github.com/opencoconut/webvtt-ruby/blob/e07d59220260fce33ba5a0c3b355e3ae88b99457/lib/webvtt/parser.rb#L11-L30
  def self.convert_from_srt(srt)
    # normalize timestamps in srt
    # This Regex looks for malformed time stamp pieces such as '00:1:00,000', '0:01:00,000', etc.
    # When it finds a match it prepends a 0 to the capture group so both of the above examples 
    # would return '00:01:00,000'
    conversion = srt.gsub(/(:|^)(\d)(,|:)/, '\10\2\3')
    # convert timestamps and save the file
    # VTT uses '.' as its decimal separator, SRT uses ',' so we convert the punctuation
    conversion.gsub!(/([0-9]{2}:[0-9]{2}:[0-9]{2})([,])([0-9]{3})/, '\1.\3')
    # normalize new line character
    conversion.gsub!("\r\n", "\n")

    "WEBVTT\n\n#{conversion}".strip
  end
end
