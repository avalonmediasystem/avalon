class NotificationsMailer < ActionMailer::Base
  default :to => Avalon::Configuration['email']['comments']

  def new_collection( args = {} )
    @collection = Admin::Collection.find(args.delete(:collection_id))
    @creator    = User.find(args.delete(:creator_id))
    @to         = User.find(args.delete(:user_id)) 
    args.each{|name, value| self.instance_variable_set("@#{name}", value)}
    mail(to: @to.email, subject: @subject)
  end

end