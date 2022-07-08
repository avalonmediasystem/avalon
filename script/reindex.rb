require 'optparse'

options = {}
OptionParser.new do |parser|
  parser.banner = "Usage: script/reindex.rb [options]"

  parser.on("-f", "--force", "Force full reindex") do |f|
    options[:force] = f
  end

  parser.on("--skip-identification", "Skip identification step which walks the Fedora graph") do |si|
    options[:skip_identification] = si
  end

  parser.on("--skip-root-node", "Skip identification step for root node") do |srn|
    options[:skip_root_node] = srn
  end

  parser.on("--skip-reindexing", "Skip reindexing step") do |sr|
    options[:skip_reindexing] = sr
  end

  parser.on("--dry-run", "Perform identification step in memory and reindexing step without writing to Solr") do |dr|
    options[:dry_run] = dr
  end

  parser.on("-s SOLR", "--solr-url SOLR_URL", "The solr connection to use (defaults $SOLR_URL)") do |s|
    options[:solr_url] = s
  end

  parser.on("-d DATABASE", "--database DATABASE", "The database connection url to use (defaults to $DATABASE_URL)") do |d|
    options[:database_url] = d
  end

  parser.on("--drop-table", "Drop reindex database table then exit") do |p|
    options[:prune] = p
  end

  parser.on("-v", "--verbose", "Verbose logging") do |v|
    options[:verbose] = v
  end

  parser.on("-h", "--help", "Prints this help") do
    puts parser
    exit
  end
end.parse!

puts "#{DateTime.now} Starting..." if options[:verbose]

solr_url = options[:solr_url]
solr_url ||= ENV['SOLR_URL']
solr = ActiveFedora::SolrService.new(url: solr_url) 

require 'sequel'
if options[:dry_run]
  DB = Sequel.sqlite # memory database, requires sqlite3
else
  database_url = options[:database_url]
  database_url ||= ENV['DATABASE_URL']
  DB = Sequel.connect(database_url)
end

if options[:prune]
  DB.drop_table(:reindexing_nodes)
  exit
end

unless DB.tables.include? :reindexing_nodes
  DB.create_table :reindexing_nodes do
    primary_key :id
    String :uri
    String :model
    DateTime :updated_at
    String :state
    index :uri
    index :state
    index [:uri, :state]
  end
end
items = DB[:reindexing_nodes]

unless options[:skip_identification]
  require 'httpx'
  http = HTTPX.plugin(:stream)
  http = http.with(headers: {"prefer" => "return=representation; include=\"http://www.w3.org/ns/ldp#PreferContainment\"; omit=\"http://www.w3.org/ns/ldp#PreferMembership\"", "accept" => "application/n-triples, */*;q=0.5"})

  unless options[:skip_root_node]
    response = http.get(ActiveFedora.fedora.base_uri, stream: true)
    response.each_line do |line|
      next unless /ldp#contains> <(?<uri>.*)> \.$/ =~ line
      items.insert(uri: uri, state: "identified")
      # Enqueue background job to do next pass on uri?
    end

    puts "#{DateTime.now} Found #{items.where(state: "identified").count} nodes as children of root node." if options[:verbose]
  end

  # Iteratively walk through the graph
  while items.where(state: "identified").count > 0 do
    puts "#{DateTime.now} Recursing down the graph..." if options[:verbose]
    items.where(state: "identified").map(:uri).each do |uri|
      begin
	updated_at = nil
	model = nil
	children = []
	response = http.get(uri, stream: true)
	response.each_line do |line|
	  if /repository#lastModified> "(?<last_modified>.*)"/ =~ line
	    updated_at = DateTime.parse(last_modified)
	  elsif /model#hasModel> "(?<has_model>.*)"/ =~ line
	    model = has_model
	  elsif /ldp#contains> <(?<child_uri>.*)> \.$/ =~ line
	    children << child_uri
	  end
	end
	if model.nil?
	  # Remove from list if not an AF::Base object
	  items.where(uri: uri).delete
	else
	  children.each { |child_uri| items.insert(uri: child_uri, state: "identified") unless items.where(uri: child_uri, state: "identified").any? }

	  if !options[:force] && items.where(uri: uri, state: "processed").any? { |item| item[:updated_at] >= updated_at }
	    state = "processed"
	  else
	    state = "waiting reindex"
	  end
	  items.where(uri: uri, state: "identified").update(updated_at: updated_at, model: model, state: state)
	end
      rescue Exception => e
        puts "Error reading #{uri}: #{e.message}"
      end
    end
  end

  puts "#{DateTime.now} Finished identifying nodes. #{items.where(state: "waiting reindex").count} flagged for reindexing." if options[:verbose]
end

unless options[:skip_reindexing]
  puts "#{DateTime.now} Attempting reindex of #{items.where(state:"waiting reindex").count} nodes." if options[:verbose]

  # Re-index
  softCommit = true
  batch_size = 50
  batch = []
  batch_uris = []
  # TODO: take batch_size of uris and pass to background job and remove rescue so it will surface
  # This could also obviate the need for the final batch processing
  # Should this actually be a cron-type job to wake up and look for items needing reindexing?
  items.where(state: "waiting reindex").map(:uri).each do |uri|
    begin
      obj = ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(uri))
      batch << obj.to_solr
      batch_uris << uri
      # Handle speedy_af indexing
      if obj.is_a? MasterFile
	obj.declared_attached_files.each_pair do |name, file|
	  batch << file.to_solr({}, external_index: true) if file.respond_to?(:update_external_index)
	end
      end
    rescue Exception => e
      puts "Error adding #{uri} to batch: #{e.message}"
      batch_uris -= [uri]
      batch.delete_if { |doc| ActiveFedora::Base.uri_to_id(uri) == doc[:id] }
      # Need to worry about removing masterfile attached files from the batch as well?
      item.where(uri: uri).update(state: "errored")
      next
    end

    if (batch.count % batch_size).zero?
      solr.conn.add(batch, params: { softCommit: softCommit }) unless options[:dry_run]
      items.where(uri: batch_uris).update(state: "processed")
      batch.clear
      batch_uris.clear
    end
  end

  if batch.present?
    solr.conn.add(batch, params: { softCommit: softCommit }) unless options[:dry_run]
    items.where(uri: batch_uris).update(state: "processed")
    batch.clear
    batch_uris.clear
  end
end

puts "#{DateTime.now} Completed" if options[:verbose]
