class CommentsController < ApplicationController
    before_filter :set_subjects
    layout 'hydrant'

    # Index replaces new in this context
	def index 
	  @comment = Comment.new
	end

	def create
	  @comment = Comment.new
	  @comment.name = params[:comment][:name]
	  @comment.email = params[:comment][:email]
	  @comment.email_confirmation = params[:comment][:email_confirmation]
	  @comment.subject = params[:comment][:subject]
	  @comment.comment = params[:comment][:comment]
	  
		if (@comment.valid? && !@comment.spam?)
		    begin
			  CommentsMailer.contact_email(@comment).deliver
			rescue Errno::ECONNRESET => e
			  logger.warn "The mail server does not appear to be responding"
			  logger.warn e
			  
			  flash[:notice] = "The message could not be sent in a timely fashion. Contact us at #{Hydrant::Configuration['email']['support']} to report the problem."
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
