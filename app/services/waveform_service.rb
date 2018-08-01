require 'audio_waveform'

class WaveformService

  def initialize(bit_res=8, samples_per_pixel=1024)
    @bit_res = bit_res
    @samples_per_pixel = samples_per_pixel
  end

  def get_waveform_json(uri)
    waveform = AudioWaveform::WaveformDataFile.new(
      sample_rate: 44100,
      samples_per_pixel: @samples_per_pixel,
      bits: @bit_res
    )
    get_normalized_peaks(uri).each {|peak| waveform.append(peak[0], peak[1]) }
    waveform
  end

private
  def get_normalized_peaks(uri)
    peaks = get_peaks(uri)
    max_peak = peaks.flatten.map(&:abs).max
    res = 2**(@bit_res-1)
    factor = (res/max_peak).to_i
    peaks.map {|peak| peak.collect {|num| (num*factor).to_i }}
  end

  def get_peaks(uri)
    temp_file = "/tmp/#{SecureRandom.uuid}.mp4"
    `ffmpeg -i #{uri} -c copy -bsf:a aac_adtstoasc #{temp_file} 2> /dev/null`
    raw_peaks = `ffprobe -f lavfi -i amovie=#{temp_file},astats=metadata=1:reset=1 -show_entries frame_tags=lavfi.astats.Overall.Min_level,lavfi.astats.Overall.Max_level -of csv=p=0 2> /dev/null`
    raw_peaks.split("\n").map {|o| o.split(",").map(&:to_f)}
  end

end
