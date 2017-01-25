class MigrationStatus < ActiveRecord::Base

  def self.summary
    counts = MigrationStatus.where(datastream: nil).group(:source_class, :status).count
    MigrationStatus.pluck(:source_class).uniq.inject({}) do |h,klass|
      h[klass] = {}
      h[klass]['completed'] = counts[[klass, 'completed']].to_i
      h[klass]['failed'] = counts[[klass, 'failed']].to_i
      h[klass]['in progress'] = counts.select { |k,v| k[0] == klass and not ['completed','failed'].include?(k[1]) }.values.sum
      h[klass]['total'] = counts.select { |k,v| k[0] == klass }.values.sum
      h
    end
  end
end
