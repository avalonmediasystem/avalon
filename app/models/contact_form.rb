class ContactForm < MailForm::Base
  attribute :fullname, :validate => true
  
  # TODO : Use a better email validation like a Gem instead of a brittle regular
  #        expression
  attribute :email, :validate => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i
  # TODO : Validate that this is equal to the original email
  attribute :email_confirmation

  attribute :comment
  attribute :nickname, :captcha => true

  def headers
    { 
		  :subject => "Comment from VoV system",
      :from => %("#{fullname}" <#{email}>),
			:to => "vovcomment@dlib.indiana.edu" 
		}
  end
end
