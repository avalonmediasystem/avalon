require 'audio_waveform'
require 'wavefile'

class WaveformService
  def initialize(bit_res = 8, samples_per_pixel = 1024)
    @bit_res = bit_res
    @samples_per_pixel = samples_per_pixel
  end

  def get_waveform_json(uri)
    waveform = AudioWaveform::WaveformDataFile.new(
      sample_rate: 44_100,
      samples_per_pixel: @samples_per_pixel,
      bits: @bit_res
    )
    get_normalized_peaks(uri).each { |peak| waveform.append(peak[0], peak[1]) }
    waveform.to_json
  end

private

  def get_normalized_peaks(uri)
    peaks = get_peaks(uri)
    max_peak = peaks.flatten.map(&:abs).max
    res = 2**(@bit_res - 1)
    factor = res / max_peak.to_f
    peaks.map { |peak| peak.collect { |num| (num * factor).to_i } }
  end

  def get_peaks(uri)
    # headers = "-headers $'Referer: https://media.dlib.indiana.edu\r\n'" if uri.starts_with? "http"
    headers = "-headers $'Referer: #{Rails.application.routes.url_helpers.root_url}\r\n'" if uri.starts_with? "http"
    cmd = "ffmpeg #{headers} -i #{uri} -f wav - 2> /dev/null"
    gather_peaks(IO.popen(cmd))
  end

  def gather_peaks(wav_file)
    peaks = []
    WaveFile::Reader.new(wav_file).each_buffer(@samples_per_pixel) do |buffer|
      peaks << [buffer.samples.flatten.min, buffer.samples.flatten.max]
    end
    peaks
  end
end
