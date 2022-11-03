# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

module BulkActionJobs
  class AccessControl < ActiveJob::Base
    queue_as :bulk_access_control
    def perform(documents, params)
      errors = []
      successes = []
      documents.each do |id|
        media_object = MediaObject.find(id)
        media_object.hidden = params[:hidden] if !params[:hidden].nil?
        media_object.visibility = params[:visibility] unless params[:visibility].blank?
        # Limited access stuff
        ["group", "class", "user", "ipaddress"].each do |title|
          if params["submit_add_#{title}"].present?
            begin_time = params["add_#{title}_begin"].blank? ? nil : params["add_#{title}_begin"]
            end_time = params["add_#{title}_end"].blank? ? nil : params["add_#{title}_end"]
            create_lease = begin_time.present? || end_time.present?

            if params[title].present?
              val = params[title].strip
              if title=='user'
                if create_lease
                  begin
                    media_object.governing_policies += [ Lease.create(begin_time: begin_time, end_time: end_time, inherited_read_users: [val]) ]
                  rescue Exception => e
                    errors += [media_object]
                  end
                else
                  media_object.read_users += [val]
                end
              elsif title=='ipaddress'
                if ( IPAddr.new(val) rescue false )
                  if create_lease
                    begin
                      media_object.governing_policies += [ Lease.create(begin_time: begin_time, end_time: end_time, inherited_read_groups: [val]) ]
                    rescue Exception => e
                      errors += [media_object]
                    end
                  else
                    media_object.read_groups += [val]
                  end
                else
                  context[:error] = "IP Address #{val} is invalid. Valid examples: 124.124.10.10, 124.124.0.0/16, 124.124.0.0/255.255.0.0"
                end
              else
                if create_lease
                  begin
                    media_object.governing_policies += [ Lease.create(begin_time: begin_time, end_time: end_time, inherited_read_groups: [val]) ]
                  rescue Exception => e
                    errors += [media_object]
                  end
                else
                  media_object.read_groups += [val]
                end
              end
            end
          end
          if params["submit_remove_#{title}"].present?
            if params[title].present?
              if ["group", "class", "ipaddress"].include? title
                media_object.read_groups -= [params[title]]
                media_object.governing_policies.each do |policy|
                  if policy.class==Lease && policy.inherited_read_groups.include?(params[title])
                    media_object.governing_policies.delete policy
                    policy.destroy
                  end
                end
              else
                media_object.read_users -= [params[title]]
                media_object.governing_policies.each do |policy|
                  if policy.class==Lease && policy.inherited_read_users.include?(params[title])
                    media_object.governing_policies.delete policy
                    policy.destroy
                  end
                end
              end
            end
          end
        end
        if errors.empty? && media_object.save
          successes += [media_object]
        else
          errors += [media_object]
        end
      end
      return successes, errors
    end
  end

  class UpdateStatus < ActiveJob::Base
    def perform(documents, user_key, params)
      errors = []
      successes = []
      status = params['action']
      documents.each do |id|
        media_object = MediaObject.find(id)
        case status
        when 'publish'
          media_object.publish!(user_key)
          # additional save to set permalink
          if media_object.save
            successes += [media_object]
          else
            errors += [media_object]
          end
        when 'unpublish'
          if media_object.publish!(nil)
            successes += [media_object]
          else
            errors += [media_object]
          end
        end
      end
      return successes, errors
    end
  end

  class Delete < ActiveJob::Base
    def perform(documents, _params)
      errors = []
      successes = []
      documents.each do |id|
        media_object = MediaObject.find(id)
        if media_object.destroy
          successes += [media_object]
        else
          errors += [media_object]
        end
      end
      return successes, errors
    end
  end

  class Move < ActiveJob::Base
    def perform(documents, params)
      collection = Admin::Collection.find( params[:target_collection_id] )
      errors = []
      successes = []
      documents.each do |id|
        media_object = MediaObject.find(id)
        media_object.collection = collection
        if media_object.save
          successes += [media_object]
        else
          errors += [media_object]
        end
      end
      return successes, errors
    end
  end

  require 'avalon/intercom'

  class IntercomPush < ActiveJob::Base
    def perform(documents, user_key, params)
      errors = []
      successes = []
      intercom = Avalon::Intercom.new(user_key)
      documents.each do |id|
        media_object = MediaObject.find(id)
        result = intercom.push_media_object(media_object, params[:collection_id], params[:include_structure] == 'true')
        if result[:link].present?
          successes += [media_object]
        elsif result[:status].present?
          error = "There was an error pushing the item. (#{result[:status]}: #{result[:message]})"
          media_object.errors[:base] << [error]
          errors += [media_object]
        else
          media_object.errors[:base] << [result[:message]]
          errors += [media_object]
        end
      end
      [successes, errors]
    end
  end

  class Merge < ActiveJob::Base
    def perform(target_id, subject_ids)
      target = MediaObject.find target_id
      subjects = subject_ids.map { |id| MediaObject.find id }
      return target.merge!(subjects)
    end
  end

  class ApplyCollectionAccessControl < ActiveJob::Base
    queue_as :bulk_access_control
    def perform(collection_id, overwrite = true)
      errors = []
      successes = []
      collection = Admin::Collection.find collection_id
      collection.media_object_ids.each do |id|
        media_object = MediaObject.find(id)
        media_object.hidden = collection.default_hidden
        media_object.visibility = collection.default_visibility
        if collection.default_enable_cdl
          media_object.lending_period = collection.default_lending_period
        end

        # Special access
        if overwrite
          media_object.read_groups = collection.default_read_groups.to_a
          media_object.read_users = collection.default_read_users.to_a
        else
          media_object.read_groups += collection.default_read_groups.to_a
          media_object.read_groups.uniq!
          media_object.read_users += collection.default_read_users.to_a
          media_object.read_users.uniq!
        end

        if media_object.save
          successes << media_object
        else
          errors << media_object
        end
      end

      [successes, errors]
    end
  end
end
