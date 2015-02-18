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

class CommentsController < ApplicationController
  before_filter :set_subjects

  # Index replaces new in this context
  def index 
    @comment = Comment.new
  end

  def create
    @comment = Comment.new
    @comment.name = params[:comment][:name]
    @comment.nickname = params[:comment][:nickname]
    @comment.email = params[:comment][:email]
    @comment.email_confirmation = params[:comment][:email_confirmation]
    @comment.subject = params[:comment][:subject]
    @comment.comment = params[:comment][:comment]

    if (@comment.valid?)
      begin
	CommentsMailer.contact_email(@comment).deliver
      rescue Errno::ECONNRESET => e
	logger.warn "The mail server does not appear to be responding \n #{e}"
	
	flash[:notice] = "The message could not be sent in a timely fashion. Contact us at #{Avalon::Configuration.lookup('email.support')} to report the problem."
	render action: "index"
      end
    else
     flash[:error] = "There were problems submitting your comment. Please correct the errors and try again."
     render action: "index"
    end 
  end
  
  protected
  def set_subjects
    @subjects = Comment::SUBJECTS
  end
end
