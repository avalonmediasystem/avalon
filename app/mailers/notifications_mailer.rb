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

class NotificationsMailer < ActionMailer::Base
  default from: Settings.email.notification

  def new_collection( args = {} )
    @collection = Admin::Collection.find(args.delete(:collection_id))
    @creator    = User.find(args.delete(:creator_id))
    @to         = User.find(args.delete(:user_id)) 
    args.each{|name, value| self.instance_variable_set("@#{name}", value)}
    mail(to: @to.email, subject: @subject)
  end

  def update_collection( args = {})
    @collection = Admin::Collection.find(args.delete(:collection_id))
    @updater    = User.find(args.delete(:updater_id))
    @to         = User.find(args.delete(:user_id)) 
    args.each{|name, value| self.instance_variable_set("@#{name}", value)}
    mail(to: @to.email, subject: @subject)
  end

end
