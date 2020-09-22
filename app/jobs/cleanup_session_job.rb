# frozen_string_literal: true
class CleanupSessionJob < ActiveJob::Base
  def perform
    sql = "DELETE FROM sessions WHERE updated_at < '#{Time.zone.today - 7.days}';"
    ActiveRecord::Base.connection.execute(sql)
  end
end
