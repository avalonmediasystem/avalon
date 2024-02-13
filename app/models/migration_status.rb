# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

class MigrationStatus < ActiveRecord::Base
  DETAIL_STATUSES = ['completed','failed','waiting']

  def self.summary
    counts = MigrationStatus.where(datastream: nil).group(:source_class, :status).count
    MigrationStatus.pluck(:source_class).uniq.inject({}) do |h,klass|
      h[klass] = {}
      DETAIL_STATUSES.each do |s|
        h[klass][s] = counts[[klass, s]].to_i
      end
      h[klass]['in progress'] = counts.select { |k,v| k[0] == klass and not DETAIL_STATUSES.include?(k[1]) }.values.sum
      h[klass]['total'] = counts.select { |k,v| k[0] == klass }.values.sum
      h
    end
  end
end
