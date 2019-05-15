# This migration comes from samvera_persona (originally 20190628003746)
class PersonaDeviseInvitableAddToUsers < ActiveRecord::Migration[5.2]
  def up
    unless ActiveRecord::Base.connection.column_exists?(:users, :invitation_token)
      change_table :users do |t|
        t.string     :invitation_token
        t.datetime   :invitation_created_at
        t.datetime   :invitation_sent_at
        t.datetime   :invitation_accepted_at
        t.integer    :invitation_limit
        t.references :invited_by, polymorphic: true
        t.integer    :invitations_count, default: 0
        t.index      :invitations_count
        t.index      :invitation_token, unique: true # for invitable
        t.index      :invited_by_id
      end
    end
  end

  def down
    change_table :users do |t|
      t.remove_references :invited_by, polymorphic: true
      t.remove :invitations_count, :invitation_limit, :invitation_sent_at, :invitation_accepted_at, :invitation_token, :invitation_created_at
    end
  end
end
