class ContactFormsController < ApplicationController
	def new 
		@mail = ContactForm.new
	end

	def create
		p = params[:contact_form] 
		@mail = ContactForm.new(fullname: p[:fullname], email: p[:email], comment: p[:comment])
		if (@mail.valid? && !@mail.spam?)
			@mail.deliver
			flash[:notice] = "Thank you for contacting us. We will get back to you as soon as possible"
			redirect_to root_path	
		else
			flash[:notice] = "Wrong email format, please try again"
			render action: "new"
		end 
	end
end
