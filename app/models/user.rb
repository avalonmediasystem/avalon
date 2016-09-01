class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors.
  include Hydra::User

  # if Blacklight::Utils.needs_attr_accessible?
  #   attr_accessible :email, :password, :password_confirmation
  # end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # devise :database_authenticatable, :registerable,
  #        :recoverable, :rememberable, :trackable, :validatable
  devise :omniauthable

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    user_key
  end

  def destroy
    Bookmark.where(user_id: self.id).destroy_all
    super
  end

  def self.find_or_create_by_username_or_email(username, email)
    self.where(username: username).first ||
    self.where(email: email).first ||
    self.create(username: username, email: email)
  end
  
  def self.from_api_token(token)
    self.find_or_create_by_username_or_email(token.username, token.email)
  end
  
  def self.find_for_lti(auth_hash, signed_in_resource=nil)
    if auth_hash.uid.blank?
      raise Avalon::MissingUserId
    end

    class_id = auth_hash.extra.context_id
    if Course.where(context_id: class_id).empty?
      class_name = auth_hash.extra.context_name
      Course.create :context_id => class_id, :label => auth_hash.extra.consumer.context_label, :title => class_name unless class_name.nil?
    end

    self.find_or_create_by_username_or_email(auth_hash.uid, auth_hash.email)
  end

  def self.autocomplete(query)
    self.where("username LIKE :q OR email LIKE :q", q: "%#{query}%").collect { |user|
      { id: user.user_key, display: user.user_key }
    }
  end

  def in?(*list)
    list.flatten.include? user_key
  end

  #TODO extract the ldap stuff into a mixin?
  def ldap_groups
    User.walk_ldap_groups(User.ldap_member_of(user_key), []).sort
  end

  def self.ldap_member_of(cn)
    return [] unless defined? Avalon::GROUP_LDAP
    entry = Avalon::GROUP_LDAP.search(:base => Avalon::GROUP_LDAP_TREE, :filter => Net::LDAP::Filter.eq("cn", cn), :attributes => ["memberof"]).first
    entry.nil? ? [] : entry["memberof"].collect {|mo| mo.split(',').first.split('=').second}
  end

  def self.walk_ldap_groups(groups, seen)
    groups.each do |g|
      next if seen.include? g
      seen << g
      User.walk_ldap_groups(User.ldap_member_of(g), seen)
    end
    seen
  end
end
