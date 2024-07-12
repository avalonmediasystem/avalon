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

require 'avalon/docx_file'

module Avalon
  class TranscriptParser
    TEXT_TYPE = ['text/vtt', 'text/srt', 'text/plain', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']

    # Passed in transcript_file must be instance of ActiveStorage::Attached::One
    def initialize(transcript_file)
      @mime_type = transcript_file.content_type
      @transcript = transcript_file.download
    end

    def plaintext
      # Transcripts can have arbitrary files imported. We need to verify that the transcript
      # is a text based file before attempting processing.
      return unless TEXT_TYPE.include? @mime_type

      unless @plaintext
        # Docx files are a zip file containing XML files so require specialized handling to retrieve the content.
        @plaintext = Avalon::DocxFile.new(@transcript).unformatted_text if @mime_type == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        # SRT and VTT files are plaintext, so it is sufficient to just download the content without additional handling.
        @plaintext ||= @transcript
      end
      @plaintext
    end

    def normalized_text
      return if plaintext.blank?

      normalized_plaintext = plaintext.gsub("\r\n", "\n")
      normalized_transcript = normalize_timed_text(normalized_plaintext) if @mime_type == 'text/vtt' || @mime_type == 'text/srt'
      normalized_transcript ||= normalized_plaintext
    end

    # Separate time cue and text content from a single line of timed text to facilitate result formatting of transcript searches.
    def self.extract_single_time_cue(timed_text)
      split_text = timed_text.match(/(\d{0,}:?\d{2}:\d{2}\.?,?\d{3} --> \d{0,}:?\d{2}:\d{2}\.?,?\d{3})(.*)/)
      return [nil, nil] if split_text.blank?
      time_cue = split_text[1].gsub(',', '.').gsub(/\s-->\s/, ',')
      text = split_text[2].strip
      [time_cue, text]
    end

    private

    def normalize_timed_text(plaintext)
      # Remove WEBVTT header and anything before the first time cue.
      # `m` flag denotes a multiline regex, so the wildcard will match newline characters.
      # Match everything before the first timecue. `.*?` is a non-greedy wildcard matcher,
      # so it will only match until the first time cue. Without the `?`, it will match everything
      # up to the last time cue.
      headers_removed = plaintext.gsub(/WEBVTT.*?(?=\d{2,}*:*\d{2}:\d{2})/m, "")
      # Remove subtitle identifiers
      # Match arbitrary text followed by a single new line character, with a lookahead to check
      # the next bit of text is a time cue.
      identifiers_removed = headers_removed.gsub(/.+\n(?=\d{2,}*:*\d{2}:\d{2})/, "")
      # Remove inline styling.
      # Match the full time cue line including everything until the new line character, 
      # putting the time cue in a capture group. Then replace the full line with the captured time cue.
      styling_removed = identifiers_removed.gsub(/(\d{2,}*:*\d{2}:\d{2}\.\d{3} --> \d{2,}*:*\d{2}:\d{2}\.\d{3}).+/, '\1')
      # Remove body notes
      # Match the NOTE designator and its associated text until the next double line break.
      # Notes can be multiline, so we need to check for two newline characters to find the end.
      notes_removed = styling_removed.gsub(/NOTE.*?(?=\n\n)/m, "")
      # Remove HTML tags because VTT files can include HTML as part of their payload and we
      # do not want that represented in the index.
      notes_removed.gsub(/<\/?[^>]*>/, '')
    end
  end
end