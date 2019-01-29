wb_path = '/srv/avalon/scriptdata/waveform_backfill.txt'
start_index = ARGV[0] || 1
row_max = ARGV[1] || 1000000

# record all master files needing waveform back-fill in a file, so if the script fails we can restart from the last processed master file
# without this file, we will solely rely on the has_waveform?_bs field, and we could run into a situation when the waveform backfill is scheduled
# but not finished, and when the script restarts it will pick up that master file again; also having this file will avoid querying solr each time
# the script needs a restart
mf_ids = []
unless File.exist? wb_path
  Rails.logger.info "Getting master files waveform info from solr and writing ids of those need back-fill to #{wb_path}"
  wb_file = File.new(wb_path, "w")
  solr = RSolr.connect url: ENV['SOLR_URL'] || "http://127.0.0.1:8983/solr/avalon"
  result = solr.get 'select', params: { q: "has_model_ssim:MasterFile", fl: ['id', 'has_waveform?_bs'], rows: row_max }
  count = 0
  result["response"]["docs"].each do |doc|
    next if doc['has_waveform?_bs']
    id = "#{doc['id']}"
    wb_file.puts id
    mf_ids << id
    count += 1
    Rails.logger.debug "to be back filled: master file #{id}"
  end
  wb_file.close
  Rails.logger.info "Found #{count} master files to be back-filled with waveform"
end

if mf_ids.empty?
  Rails.logger.info "Reading ids of master files needing waveform back-fill from #{wb_path}"
  File.readlines(wb_file).each do |id|
    mf_ids << id
    Rails.logger.debug "to be back filled: master file #{id}"
  end
end

mf_ids.each_with_index do |id, i|
  next if i+1 < start_index
  WaveformJob.perform_later(id)
  Rails.logger.info "Scheduled WavefromJob for master file #{id} on line #{i+1}"
end
