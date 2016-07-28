# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

namespace :avalon do
  desc 'migrate databases for the rails app and the active annotations gem'
  task :db_migrate do
    `rake db:migrate`
    `rails generate active_annotations:install`
  end
  namespace :services do
    services = ["jetty", "felix", "delayed_job"]
    desc "Start Avalon's dependent services"
    task :start do
      services.map { |service| Rake::Task["#{service}:start"].invoke }
    end
    desc "Stop Avalon's dependent services"
    task :stop do
      services.map { |service| Rake::Task["#{service}:stop"].invoke }
    end
    desc "Status of Avalon's dependent services"
    task :status do
      services.map { |service| Rake::Task["#{service}:status"].invoke }
    end
    desc "Restart Avalon's dependent services"
    task :restart do
      services.map { |service| Rake::Task["#{service}:restart"].invoke }
    end
   end
  namespace :assets do
   desc "Clears javascripts/cache and stylesheets/cache"
   task :clear => :environment do
     FileUtils.rm(Dir['public/javascripts/cache/[^.]*'])
     FileUtils.rm(Dir['public/stylesheets/cache/[^.]*'])
   end
  end
  namespace :derivative do
   desc "Sets streaming urls for derivatives based on configured content_path in avalon.yml"
   task :set_streams => :environment do
     Derivative.find_each({},{batch_size:5}) do |derivative|
       derivative.set_streaming_locations!
       derivative.save!
     end
   end
  end
  namespace :batch do
    desc "Starts Avalon batch ingest"
    task :ingest => :environment do
      # Starts the ingest process
      require 'avalon/batch/ingest'

      WithLocking.run(name: 'batch_ingest') do
        Admin::Collection.all.each do |collection|
          Avalon::Batch::Ingest.new(collection).ingest
        end
      end
    end
  end
  namespace :user do
    desc "Create user (assumes identity authentication)"
    task :create => :environment do
      if ENV['avalon_username'].nil? or ENV['avalon_password'].nil?
        abort "You must specify a username and password.  Example: rake avalon:user:create avalon_username=user@example.edu avalon_password=password avalon_groups=group1,group2"
      end

      require 'role_controls'
      username = ENV['avalon_username'].dup
      password = ENV['avalon_password']
      groups = ENV['avalon_groups'].split(",")

      Identity.create!(email: username, password: password, password_confirmation: password)
      User.create!(username: username, email: username)
      groups.each do |group|
        RoleControls.add_role(group) unless RoleControls.role_exists? group
        RoleControls.add_user_role(username, group)
      end

      puts "User #{username} created and added to groups #{groups}"
    end
    desc "Delete user"
    task :delete => :environment do
      if ENV['avalon_username'].nil?
        abort "You must specify a username  Example: rake avalon:user:delete avalon_username=user@example.edu"
      end

      require 'role_controls'
      username = ENV['avalon_username'].dup
      groups = RoleControls.user_roles username

      Identity.where(email: username).destroy_all
      User.where(username: username).destroy_all
      groups.each do |group|
        RoleControls.remove_user_role(username, group)
      end

      puts "Deleted user #{username} and removed them from groups #{groups}"
    end
    desc "Change password (assumes identity authentication)"
    task :passwd => :environment do
      if ENV['avalon_username'].nil? or ENV['avalon_password'].nil?
        abort "You must specify a username and password.  Example: rake avalon:user:passwd avalon_username=user@example.edu avalon_password=password"
      end

      username = ENV['avalon_username'].dup
      password = ENV['avalon_password']
      Identity.where(email: username).each {|identity| identity.password = password; identity.save}

      puts "Updated password for user #{username}"
    end
  end

  namespace :test do
    desc "Create a test media object"
    task :media_object => :environment do
      require 'factory_girl'
      require 'faker'
      Dir[Rails.root.join("spec/factories/**/*.rb")].each {|f| require f}

      mf_count = [ENV['master_files'].to_i,1].max
      mo = FactoryGirl.create(:media_object)
      mf_count.times do |i|
        FactoryGirl.create(:master_file_with_derivative, mediaobject: mo)
      end
      puts mo.pid
    end
  end

  desc "Reindex all Avalon objects"
  task :reindex => :environment do
    query = "pid~#{Avalon::Configuration.lookup('fedora.namespace')}:*"
    #Override of ActiveFedora::Base.reindex_everything("pid~#{prefix}:*") including error handling/reporting
    ActiveFedora::Base.send(:connections).each do |conn|
      conn.search(query) do |object|
        next if object.pid.start_with?('fedora-system:')
        begin
          ActiveFedora::Base.find(object.pid).update_index
        rescue
          puts "#{object.pid} failed reindex"
        end
      end
    end
  end

  desc "Identify invalid Avalon Media Objects"
  task :validate => :environment do
    MediaObject.find_each({},{batch_size:5}) {|mo| puts "#{mo.pid}: #{mo.errors.full_messages}" if !mo.valid? }
  end

  namespace :variations do
    desc "Import playlists/bookmarks from Variation export"
    task :import => :environment do
      if ENV['filename'].nil?
        abort "You must specify a file. Example: rake avalon:variations:import filename=export.json"
      end
      puts "Importing JSON file: #{ENV['filename']}"
      unless File.file?(ENV['filename'])
        abort "Could not find specified file"
      end
      require 'json'
      require 'htmlentities'
      f = File.open(ENV['filename'])
      s = f.read()
      import_json = JSON.parse(s)
      f.close()
      user_count = 0
      new_user_count = 0
      user_errors = []
      new_playlist_count = 0
      playlist_errors = []
      item_count = 0
      new_item_count = 0
      item_errors = []
      bookmark_count = 0
      new_bookmark_count = 0
      bookmark_errors = []

      # Setup temporary tables to hold existing playlist data. Allows for re-importing of bookmark data without creating duplicates.
      conn = ActiveRecord::Base.connection
      conn.execute("DROP TABLE IF EXISTS temp_playlist")
      conn.execute("DROP TABLE IF EXISTS temp_playlist_item")
      conn.execute("DROP TABLE IF EXISTS temp_marker")
      conn.execute("CREATE TABLE temp_playlist (id int primary key, title text, user_id int)")
      conn.execute("CREATE TABLE temp_playlist_item (id int primary key, playlist_id int, user_id int, clip_id int, master_file text, position int, title text, start_time int, end_time int)")
      conn.execute("CREATE TABLE temp_marker (id int primary key, playlist_item_id int, master_file text, title text, start_time int)")

      # Save existing playlist/item/marker data for users being imported
      puts "Compiling existing avalon marker data"
      usernames = import_json.collect{|user|user['username']}
      Playlist.where(user_id: User.where(username: usernames)).each do |playlist|
        sql = ActiveRecord::Base.send(:sanitize_sql_array, ["INSERT INTO temp_playlist VALUES (?, ?, ?)", playlist.id, playlist.title, playlist.user_id])
        conn.execute(sql)
        playlist.items.each do |item|
          sql = ActiveRecord::Base.send(:sanitize_sql_array, ["INSERT INTO temp_playlist_item VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", item.id, item.playlist_id, playlist.user_id, item.clip_id, item.master_file.pid, item.position, item.title, item.start_time, item.end_time])
          conn.execute(sql)
          item.marker.each do |marker|
            sql = ActiveRecord::Base.send(:sanitize_sql_array, ["INSERT INTO temp_marker VALUES (?,?,?,?,?)", marker.id, item.id, marker.master_file.pid, marker.title, marker.start_time])
            conn.execute(sql)
          end
        end
      end

      # Import each user's playlist
      import_json.each do |user|
        user_count += 1
        user_obj = User.find_by_username(user['username'])
        unless user_obj.present?
          user_obj = User.create(username: user['username'], email: "#{user['username']}@indiana.edu")
          unless user_obj.persisted?
            user_errors += [{username: user['username'], errors: user_obj.errors.full_messages}]
          end
          new_user_count += 1
        end
        playlist_name = user['playlist_name']
        puts "Importing user #{user['username']}"
        puts "  playlist name: #{playlist_name}"

        playlist_obj = Playlist.where(user_id: user_obj, title: playlist_name).first
        unless playlist_obj.present?
          playlist_obj = Playlist.create(user: user_obj, title: playlist_name, visibility: 'private')
          unless playlist_obj.persisted?
            playlist_errors += [{username: user['username'], title: playlist_name, errors: playlist_obj.errors.full_messages}]
          end
          new_playlist_count += 1
        end

        user['playlist_item'].each do |playlist_item|
          container = playlist_item['container_string']
          comment = HTMLEntities.new.decode(playlist_item['comment'])
          title = HTMLEntities.new.decode(playlist_item['name'])
          mf_obj = MasterFile.where("dc_identifier_tesim:#{container}").first
          unless mf_obj.present?
            item_errors += [{username: user['username'], playlist_id: playlist_obj.id, container: container, title: title, errors: ['Masterfile not found']}]
            next 
          end
          item_count += 1
          puts "  Importing playlist item #{title}"
          sql = ActiveRecord::Base.send(:sanitize_sql_array, ["SELECT id FROM temp_playlist_item WHERE playlist_id=? and master_file=? and title=?", playlist_obj.id, mf_obj.pid, title])
          playlist_item_id = conn.exec_query(sql)
          pi_obj = !playlist_item_id.empty? ? PlaylistItem.find(playlist_item_id.first['id']) : []
          unless pi_obj.present?
            clip_obj = AvalonClip.create(title: title, master_file: mf_obj, start_time: 0, comment: comment)
            pi_obj = PlaylistItem.create(clip: clip_obj, playlist: playlist_obj)
            unless pi_obj.persisted?
              item_errors += [{username: user['username'], playlist_id: playlist_obj.id, container: container, title: title, errors: pi_obj.errors.full_messages}]
              next
            end
            new_item_count += 1
          end
          playlist_item['bookmark'].each do |bookmark|
            bookmark_count += 1
            bookmark_name = HTMLEntities.new.decode(bookmark['name'])
            sql = ActiveRecord::Base.send(:sanitize_sql_array, ["SELECT id FROM temp_marker WHERE playlist_item_id=? and title=? and start_time=?", pi_obj.id, bookmark_name, bookmark['start_time']])
            bookmark_id = conn.exec_query(sql)
            bookmark_obj = !bookmark_id.empty? ? AvalonMarker.find(bookmark_id.first['id']) : []
            unless bookmark_obj.present?
              marker_obj = AvalonMarker.create(playlist_item: pi_obj, title: bookmark_name, master_file: mf_obj, start_time: bookmark['start_time'])
              unless marker_obj.persisted?
                bookmark_errors += [{username: user['username'], playlist_id: playlist_obj.id, playlist_item_id: pi_obj.id, container: container, playlist_item_title: title, bookmark_title: bookmark_name, bookmark_start_time: bookmark['start_time'], errors: marker_obj.errors.full_messages}]
                next
              end
              new_bookmark_count += 1
            end
            puts "    Importing bookmark #{bookmark_name} (#{bookmark['start_time']})"
          end
        end
      end
      conn.execute("DROP TABLE IF EXISTS temp_playlist")
      conn.execute("DROP TABLE IF EXISTS temp_playlist_item")
      conn.execute("DROP TABLE IF EXISTS temp_marker")
      puts "------------------------------------------------------------------------------------"
      puts "Errors"
      puts " user_errors = #{user_errors}" if user_errors.present?
      puts " playlist_errors = #{playlist_errors}" if playlist_errors.present?
      puts " item_errors = #{item_errors}" if item_errors.present?
      puts " bookmark_errors = #{bookmark_errors}" if bookmark_errors.present?
      puts "------------------------------------------------------------------------------------"
      puts "Imported #{user_count} users with #{bookmark_count} bookmarks in #{item_count} valid playlist items"
      puts " Created #{new_user_count} new users (#{user_errors.length} errors)"
      puts " Created #{new_playlist_count} new playlists (#{playlist_errors.length} errors)"
      puts " Created #{new_item_count} new playlist items (#{item_errors.length} errors)"
      puts " Created #{new_bookmark_count} new bookmarks (#{bookmark_errors.length} errors)"
    end
  end
end
