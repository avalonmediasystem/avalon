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

# Script for reindexing an Avalon instance into an empty solr instance
# 
# This script intends to be rerunnable and more resilient than the rake avalon:reindex task and utilizes a database
# to store information that is used while the script is running and for future runs.
#
# The database connection defaults to the $DATABASE_URL env variable or can be set with the --database option.
# A single table will be createed for this script and can be dropped using the --drop-table option to clean
# out the database prior to running.
#
# There are two phases to this process: identification and reindexing
#
# Identification populates the database with a row for each object to be reindexed.  The source for this information
# can be either a treewalk of the Fedora repository or the existing solr instance.  (While the existing solr instance
# is not the system of record it may be the only option if the Fedora instance is too large to be performant and leads
# to timeout issues.  It should also be noted that the fedora treewalk will probably take 100x or more than reading
# from solr.)  If reading from a solr instance set the --read-solr-url option.  The fedora instance used for
# reading will be the one configured for avalon.  If you need to rerun the identification step and wish to skip re-reading
# the root node you can use the --skip-root-node option.
#
# After the identification step the database should be populated with rows that look like the following:
#
# | id | uri | state | updated_at | state_changed_at |
#
# The state is initialized to 'identified' when a uri is first seen during the fedora treewalk and then set to 'waiting reindex'
# when it has been walked.  When reading from solr, the 'identified' state is skipped and state is initialized to 'waiting reindex'.
#
# The updated_at timestamp comes from fedora/solr and represents the last time the object was modified white the state_changed_at
# timestamp is for when the reindexing script last modified the state of a uri.  The updated_at time is used to avoid duplicate
# entries if this script is run multiple times.
#
# When identifiecation has completed the script will then proceed to reindexing.  The reindexing will happen in the solr
# instance configured by either the $SOLR_URL env variable or the -s option.
# There are a few options for tuning the reindex process:
# The --parallel-indexing option will process the list of uris waiting reindexing in 10 concurrent threads using batches
# configured by the --batch-size option (default 50).
# The --reindex-limit option limits the number of items processed by the script in one run.  This could be useful during testing to
# avoid having to run the whole list of uris waiting reindexing.
#
# During reindexing the state of uris will be updated to either 'processed', 'errored', or 'skipped'.  Uris are 'skipped' if they
# are child objects that are handled specially and indexed when the parent object is indexed.  At this time no error information
# is kept in the database.
#
# When running or re-running the script it can be useful sometimes to target one of the two phases.  The --skip-identification
# and --skip-reindexing options allow running one or the other of the phases.  The --dry-run option is also useful for testing
# or for guaging how long the script will take to run.  Logging can be enabled using the --verbose option.
#
# Delta reindexing (currently only implemented for reading from solr for identification)
#
# Because a single run of the reindexing process can take days there is the likely possiblity that the Avalon instance has been
# modified by creating, deleting, or editing content.  To quickly catch up, this script can be run again with the --delta option.
# This will identify only objects that have been created, modified, or deleted since the last update_at timestamp of the objects
# already processed minus one day.  This should run quickly (< 1 hour).
#
# This script was written for migrating from solr 6 to solr 8/9 with the following process in mind:
# 1. Reindex from solr 6 into new solr 8 instance
# 2. Configure avalon to use new solr 8 instance and restart
# 3. Run reindex delta to read from solr 6 and catch any items that have changed since step 1


require 'optparse'

options = {}
OptionParser.new do |parser|
  parser.banner = "Usage: RAILS_ENV=production nohup bundle exec rails r reindex.rb [options] &"

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

  parser.on("--read-solr-url READ_SOLR_URL", "The solr connection to read from for identification instead of fedora") do |rs|
    options[:read_solr_url] = rs
  end

  parser.on("--reindex-limit REINDEX_LIMIT", "Limit reindexing to a set number of items") do |rl|
    options[:reindex_limit] = rl
  end

  parser.on("--parallel-indexing", "Reindex using paralellism") do |p|
    options[:parallel_indexing] = p
  end

  parser.on("--batch-size", "Size of batches for indexing (default: 50)") do |bs|
    options[:batch_size] = bs
  end

  parser.on("--delta", "Only find changes since last reindexing") do |d|
    options[:delta] = d
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

read_solr_url = options[:read_solr_url]
read_solr = ActiveFedora::SolrService.new(url: read_solr_url) if read_solr_url.present?

require 'sequel'
if options[:dry_run]
  DB = Sequel.sqlite # memory database, requires sqlite3
else
  database_url = options[:database_url]
  database_url ||= ENV['DATABASE_URL']
  DB = Sequel.connect(database_url, max_connections: 20, pool_timeout: 10)
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
    DateTime :state_changed_at
    index :uri
    index :state
    index :state_changed_at
    index [:uri, :state]
  end
end
items = DB[:reindexing_nodes]

unless options[:skip_identification]
  if options[:read_solr_url]
    # Paginate this to avoid having one really large request?
    query = "has_model_ssim:[* TO *]"
    if options[:delta]
      last_updated_at = items.order(:updated_at).last[:updated_at]
      query += " AND timestamp:[#{(last_updated_at - 1.day).utc.iso8601} TO *]"
    end
    docs = read_solr.conn.get("select", params: { q: query, qt: 'standard', fl: ["id", "timestamp", "has_model_ssim"], rows: 1_000_000_000 })["response"]["docs"]
    docs.map do |doc|
      # Need to transform ids into uris to match what we get from crawling fedora
      doc["id"] = ActiveFedora::Base.id_to_uri(doc["id"])
      # Need to transform timestamps into DateTime objects
      doc["timestamp"] = DateTime.parse(doc["timestamp"])
      model = doc["has_model_ssim"]&.first
      doc["model"] = model if model
      doc.delete("has_model_ssim")
    end
    docs.reject! do |doc|
      # Skip those that are already waiting reindex
      items.where(uri: doc["id"], state: "waiting reindex").any? ||
      # Skip those which haven't changed
      items.where(uri: doc["id"]).where(Sequel.lit('updated_at >= ?', doc["timestamp"])).any?
    end
    items.import([:uri, :updated_at, :model, :state, :state_changed_at], docs.map(&:values).product([["waiting reindex", DateTime.now]]).map(&:flatten), commit_every: 10_000)

    if options[:delta]
      already_deleted_uris = items.where(state: ["waiting deletion", "deleted"]).order(:uri).distinct(:uri).select(:uri).pluck(:uri)
      already_indexed_uris = items.order(:uri).distinct(:uri).select(:uri).pluck(:uri)
      ids = read_solr.conn.get("select", params: { q: "has_model_ssim:[* TO *]", qt: 'standard', fl: ["id"], sort: "id asc", rows: 1_000_000_000 })["response"]["docs"].pluck("id")
      uris = ids.collect { |id| ActiveFedora::Base.id_to_uri(id) }
      uris_to_delete = already_indexed_uris - already_deleted_uris - uris
      items.import([:uri, :state, :state_changed_at], uris_to_delete.product([["waiting deletion", DateTime.now]]).map(&:flatten), commit_every: 10_000)
    end
  else
    require 'httpx'
    http = HTTPX.plugin(:stream)
    http = http.with(headers: {"prefer" => "return=representation; include=\"http://www.w3.org/ns/ldp#PreferContainment\"; omit=\"http://www.w3.org/ns/ldp#PreferMembership\"", "accept" => "application/n-triples, */*;q=0.5"})

    unless options[:skip_root_node]
      response = http.get(ActiveFedora.fedora.base_uri, stream: true)
      response.each_line do |line|
	next unless /ldp#contains> <(?<uri>.*)> \.$/ =~ line
	items.insert(uri: uri, state: "identified", state_changed_at: DateTime.now) unless items.where(uri: uri, state: "identified").any?
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
	    children.each { |child_uri| items.insert(uri: child_uri, state: "identified", state_changed_at: DateTime.now) unless items.where(uri: child_uri, state: "identified").any? }

	    if !options[:force] && items.where(uri: uri, state: "processed").any? { |item| item[:updated_at] >= updated_at }
	      state = "processed"
	    else
	      state = "waiting reindex"
	    end
	    items.where(uri: uri, state: "identified").update(updated_at: updated_at, model: model, state: state, state_changed_at: DateTime.now)
	  end
	rescue Exception => e
	  puts "#{DateTime.now} Error reading #{uri}: #{e.message}"
	end
      end
    end
  end

  puts "#{DateTime.now} Finished identifying nodes. #{items.where(state: "waiting reindex").count} flagged for reindexing." if options[:verbose]
  puts "#{DateTime.now} #{items.where(state: "waiting deletion").count} flagged for deletion." if options[:verbose] && options[:delta]
end

# Re-index
unless options[:skip_reindexing]
  reindex_limit = options[:reindex_limit] || nil
  if reindex_limit
    puts "#{DateTime.now} Attempting reindex of #{reindex_limit} nodes out of #{items.where(state:"waiting reindex").count}." if options[:verbose]
  else
    puts "#{DateTime.now} Attempting reindex of #{items.where(state:"waiting reindex").count} nodes." if options[:verbose]
  end

  batch_size = options[:batch_size] || 50
  softCommit = true
  uris_to_skip = [/\/poster$/, /\/thumbnail$/, /\/waveform$/, /\/captions$/, /\/structuralMetadata$/]

  models_for_all = DB[:reindexing_nodes].map(:model).uniq - ["Hydra::AccessControl", "Hydra::AccessControls::Permission", "Admin::Collection"]
  model_prioritization = ["Hydra::AccessControl", "Hydra::AccessControls::Permission", "Admin::Collection", models_for_all]

  model_prioritization.each do |model|
    items_for_reindexing_relation = items.where(state: "waiting reindex", model: model).limit(reindex_limit).map(:uri)

    if options[:parallel_indexing]
      require 'parallel'
      require 'ruby-progressbar'

      Parallel.each(items_for_reindexing_relation.each_slice(batch_size), in_threads: 10, progress: "Reindexing") do |uris|
        batch = []
        batch_uris = []

        uris.each do |uri|
          begin
            if uris_to_skip.any? { |pattern| uri =~ pattern }
              items.where(uri: uri, state: "waiting reindex").update(state: "skipped", state_changed_at: DateTime.now)
              next
            end
            obj = ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(uri))
            batch << (obj.is_a?(MediaObject) ? obj.to_solr(include_child_fields: true) : obj.to_solr)
            batch_uris << uri
            # Handle speedy_af indexing
            if obj.is_a?(MasterFile) || obj.is_a?(Admin::Collection)
              obj.declared_attached_files.each_pair do |name, file|
                batch << file.to_solr({}, external_index: true) if file.present? && file.respond_to?(:update_external_index)
              end
            end
          rescue Exception => e
            puts "#{DateTime.now} Error adding #{uri} to batch: #{e.message}"
            puts e.backtrace if options[:verbose]
            batch_uris -= [uri]
            batch.delete_if { |doc| ActiveFedora::Base.uri_to_id(uri) == doc[:id] }
            # Need to worry about removing masterfile attached files from the batch as well?
            items.where(uri: uri, state: "waiting reindex").update(state: "errored", state_changed_at: DateTime.now)
            next
          end
        end

        begin
          solr.conn.add(batch, params: { softCommit: softCommit }) unless options[:dry_run]
          items.where(uri: batch_uris, state: "waiting reindex").update(state: "processed", state_changed_at: DateTime.now)
        rescue Exception => e
          puts "#{DateTime.now} Error persisting batch to solr: #{e.message}"
          puts e.backtrace if options[:verbose]
          items.where(uri: batch_uris, state: "waiting reindex").update(state: "errored", state_changed_at: DateTime.now)
        end
      end
    else
      batch = []
      batch_uris = []
      items_for_reindexing_relation.each do |uri|
        begin
          obj = ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(uri))
          batch << (obj.is_a?(MediaObject) ? obj.to_solr(include_child_fields: true) : obj.to_solr)
          batch_uris << uri
          # Handle speedy_af indexing
          if obj.is_a?(MasterFile) || obj.is_a?(Admin::Collection)
            obj.declared_attached_files.each_pair do |name, file|
              batch << file.to_solr({}, external_index: true) if file.present? && file.respond_to?(:update_external_index)
            end
          end
        rescue Exception => e
          puts "#{DateTime.now} Error adding #{uri} to batch: #{e.message}"
          puts e.backtrace if options[:verbose]
          batch_uris -= [uri]
          batch.delete_if { |doc| ActiveFedora::Base.uri_to_id(uri) == doc[:id] }
          # Need to worry about removing masterfile attached files from the batch as well?
          items.where(uri: uri, state: "waiting reindex").update(state: "errored", state_changed_at: DateTime.now)
          next
        end

        if (batch.count % batch_size).zero?
          solr.conn.add(batch, params: { softCommit: softCommit }) unless options[:dry_run]
          items.where(uri: batch_uris, state: "waiting reindex").update(state: "processed", state_changed_at: DateTime.now)
          batch.clear
          batch_uris.clear
          puts "#{DateTime.now} #{items.where(state: "processed").count} processed" if options[:verbose]
        end
      end

      if batch.present?
        solr.conn.add(batch, params: { softCommit: softCommit }) unless options[:dry_run]
        items.where(uri: batch_uris, state: "waiting reindex").update(state: "processed", state_changed_at: DateTime.now)
        batch.clear
        batch_uris.clear
      end
    end
  end

  if options[:delta]
    begin
      puts "#{DateTime.now} Attempting deletion of #{items.where(state:"waiting deletion").count} nodes." if options[:verbose]
      ids = items.where(state: "waiting deletion").map(:uri).collect { |uri| id = ActiveFedora::Base.uri_to_id(uri) }
      if ids.present?
        solr.conn.delete_by_id(ids)
	solr.conn.commit
        items.where(state: "waiting deletion").update(state: "deleted", state_changed_at: DateTime.now)
      end
    rescue Exception => e
      puts "#{DateTime.now} Error adding #{uri} to batch: #{e.message}"
      puts e.backtrace if options[:verbose]
      items.where(state: "waiting deletion").update(state: "errored", state_changed_at: DateTime.now)
    end
  end

  # Do a final hard commit and optimize
  solr.conn.commit
  solr.conn.optimize
end

puts "#{DateTime.now} Completed" if options[:verbose]
