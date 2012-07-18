class CommentsMailer < ActionMailer::Base
  default :to => "vovcomment@dlib.indiana.edu"
  
  def contact_email(comment)
    @comment = comment
    mail(:from => comment.email, :subject => comment.subject)
  end
end