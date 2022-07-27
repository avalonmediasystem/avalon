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
