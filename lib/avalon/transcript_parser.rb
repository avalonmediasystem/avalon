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

module Avalon
  module TranscriptParser
    TEXT_TYPE = ['text/vtt', 'text/srt', 'text/plain', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
    # Passed in transcript_file must be instance of ActiveStorage::Attached::One
    def self.transcript_plaintext transcript_file
      mime_type = transcript_file.content_type
      # Transcripts can have arbitrary files imported. We need to verify that the transcript
      # is a text based file before attempting processing.
      return unless TEXT_TYPE.include? mime_type
      # Docx files are a zip file containing XML files so require specialized handling to retrieve the content.
      plaintext = Zip::File.open_buffer(transcript_file.download).parse_docx if mime_type == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      # SRT and VTT files are plaintext, so it is sufficient to just download the content without additional handling.
      plaintext ||= transcript_file.download
    end

    # Passed in transcript_file must be instance of ActiveStorage::Attached::One
    def self.normalize_transcript transcript_file
      plaintext = self.transcript_plaintext(transcript_file)
      return if plaintext.blank?

      normalized_plaintext = plaintext.gsub("\r\n", "\n")
      # We only need the time cues and associated text content indexed so we remove the subtitle
      # numbers and the VTT header, if present.
      headerless_plaintext = normalized_plaintext.gsub(/WEBVTT.+?(?=\d{2}:\d{2}:\d{2})/m, "")
      headerless_plaintext.gsub(/\d+\n(?=\d{2}:\d{2}:\d{2})/, "")
    end
  end
end