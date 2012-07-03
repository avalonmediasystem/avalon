class ContactForm < MailForm::Base
  attribute :fullname, :validate => true
  attribute :email, :validate => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i
  attribute :comment
	attribute :nickname, :captcha => true

  def headers
    { 
		  :subject => "Comment for VoV",
      :from => %("#{fullname}" <#{email}>),
			:to => "vovcomment@dlib.indiana.edu" 
		}
  end
end
