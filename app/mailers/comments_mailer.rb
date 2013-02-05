class CommentsMailer < ActionMailer::Base
  default :to => Hydrant::Configuration['email']['comments']
  
  def contact_email(comment)
    @comment = comment
    mail(:from => comment.email, :subject => comment.subject)
  end
end