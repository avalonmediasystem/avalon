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

namespace :avalon do
  namespace :token do
    desc "List API tokens"
    task :list => :environment do
      user = ENV['username']
      criteria = { username: user }.reject { |k,v| v.nil? }
      ApiToken.where(criteria).each do |api_token|
        puts [api_token.token,api_token.username].join('|')
      end
    end
    
    desc "Generate an API token for a user"
    task :generate => :environment do
      user = ENV['username']
      email = ENV['email']
      token = ENV['token']
      unless user.present? and email.present?
        abort "You must specify a username and email address. Example: rake avalon:token:generate username=archivist email=archivist1@example.com"
      end
      new_token = ApiToken.create username: user, email: email, token: token
      puts new_token.token
    end
    
    desc "Revoke an API token or all of a given user's API tokens"
    task :revoke => :environment do
      user = ENV['username']
      token = ENV['token']
      if (user.blank? and token.blank?) or (user.present? and token.present?)
        abort "You must specify a username OR a token but not both. Example: rake avalon:token:revoke username=archivist"
      end
      criteria = { username: user, token: token }.reject { |k,v| v.nil? }
      ApiToken.where(criteria).each do |api_token|
        api_token.destroy
        puts "Token `#{api_token.token}` (#{api_token.username}) revoked."
      end
    end
  end
end
