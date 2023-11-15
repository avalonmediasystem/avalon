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

require 'audio_waveform'
require 'wavefile'

class WaveformService
  def initialize(bit_res = 8, samples_per_pixel = 1024)
    @bit_res = bit_res
    @samples_per_pixel = samples_per_pixel
  end

  def get_waveform_json(uri)
    return nil unless uri.present?
    waveform = AudioWaveform::WaveformDataFile.new(
      sample_rate: 44_100,
      samples_per_pixel: @samples_per_pixel,
      bits: @bit_res
    )

    peaks = if uri.scheme == 's3'
              begin
                local_file = FileLocator::S3File.new(uri).local_file
                get_normalized_peaks(local_file.path)
              ensure
                local_file.close!
              end
            else
              get_normalized_peaks(uri)
            end

    peaks.each { |peak| waveform.append(peak[0], peak[1]) }
    return nil if waveform.size.zero?
    waveform.to_json
  end

  def empty_waveform(master_file)
    max_peak = 1.0
    min_peak = -1.0
    peaks_length = (44_100 * (master_file.duration.to_i / 1000)) / @samples_per_pixel.to_i
    peaks_data = Array.new(peaks_length) { Array.new(2) }
    peaks_data.each do |peak|
      data_points = [rand * ((max_peak - min_peak) + min_peak), rand * ((max_peak - min_peak) + min_peak)]
      peak[0] = data_points.min
      peak[1] = data_points.max
    end

    empty_waveform = AudioWaveform::WaveformDataFile.new(
      sample_rate: 44_100,
      samples_per_pixel: @samples_per_pixel,
      bits: @bit_res
    )

    peaks_data.each { |peak| empty_waveform.append(peak[0], peak[1]) }

    waveform = IndexedFile.new
    waveform.original_name = 'empty_waveform.json'
    waveform.content = Zlib::Deflate.deflate(empty_waveform.to_json)
    waveform.mime_type = 'application/zlib'
    waveform
  end

private

  def get_normalized_peaks(uri)
    wave_io = get_wave_io(uri.to_s)
    peaks = gather_peaks(wave_io)
    return [] if peaks.blank?
    max_peak = peaks.flatten.map(&:abs).max
    res = 2**(@bit_res - 1)
    factor = max_peak.zero? ? 1 : res / max_peak.to_f
    peaks.map { |peak| peak.collect { |num| (num * factor).to_i } }
  ensure
    Process.wait(wave_io.pid) if wave_io&.pid
  end

  def get_wave_io(uri)
    headers = "-headers $'Referer: #{Rails.application.routes.url_helpers.root_url}\r\n'" if uri.starts_with? "http"
    normalized_uri = uri.starts_with?("file") ? Addressable::URI.unencode(uri) : uri
    timeout = 60000000 # Must be in microseconds. Current value = 1 minute.
    cmd = "#{Settings.ffmpeg.path} #{headers} -rw_timeout #{timeout} -i '#{normalized_uri}' -f wav -ar 44100 - 2> /dev/null"
    IO.popen(cmd)
  end

  def gather_peaks(wav_file)
    peaks = []
    begin
      WaveFile::Reader.new(wav_file).each_buffer(@samples_per_pixel) do |buffer|
        peaks << [buffer.samples.flatten.min, buffer.samples.flatten.max]
      end
    rescue WaveFile::InvalidFormatError
      # ffmpeg generated no wavefile data
    end
    peaks
  end
end
