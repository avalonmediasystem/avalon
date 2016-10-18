module BulkActionJobs
  class AccessControl < ActiveJob::Base
    queue_as :bulk_access_control
    def perform documents, params
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
    def perform documents, user_key, params
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
    def perform documents, params
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
    def perform documents, params
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
end
