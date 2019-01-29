wb_file = '/srv/avalon/scriptdata/waveform_backfill.txt'
# TODO use cmdline param for start_index
start_index = 1

master_files = []
unless File.exist? file
  Rails.logger.info "Getting master files waveform info from solr and writing ids of those need back-fill to waveform_backfill file"
  master_file_file = File.new(wb_file, "w")
  solr = RSolr.connect url: 'http://127.0.0.1:8983/solr/avalon'
  # TODO slor query?
  result = solr.get 'select', params: { q: "has_master_filedel_ssim:MasterFile", fl: [:id, :has_waveform?_bs], rows: 1000000 }
  count = 0
  result["response"]["docs"].each do |doc|
    next if doc['has_waveform?_bs']
    id = "#{doc['id']}"
    master_file_file.puts id
    master_files << id
    count += 1
    Rails.logger.debug "MasterFile #{id}"
  end
  master_file_file.close
  Rails.logger.info "Found #{count} master files to have waveform back-filled"
end

if master_files.empty?
  Rails.logger.info "Reading ids of master files to have waveform back-filled from waveform_backfill file"
  File.readlines(master_file_file).each do |line|
    master_files << line
    Rails.logger.info line
  end
end

master_files.each_with_index do |id, i|
  next if i+1 < start_index
  WaveformJob.perform_later(master_file.id)
  Rails.logger.info "Scheduled WavefromJob for master file #{id} on line #{i+1}"
end
