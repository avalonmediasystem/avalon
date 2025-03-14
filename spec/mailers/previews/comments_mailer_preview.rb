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

class CommentsMailerPreview < ActionMailer::Preview
  def contact_email
    @comment = Comment.new
    @comment.name = 'Eddie Munson'
    @comment.nickname = ''
    @comment.email = 'emunson@archive.edu'
    @comment.email_confirmation = 'emunson@archive.edu'
    @comment.subject = "General feedback"
    @comment.comment = 'Testing, testing, testing'

    CommentsMailer.contact_email(@comment.to_h)
  end
end
