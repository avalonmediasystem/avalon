# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

module NoidValidator
  extend ActiveSupport::Concern

  include Identifier

  included do
    before_action :validate_noid, only: [:show]
  end

  private

  def validate_noid
    return if noid_service.valid?(params[:id])

    # Strip all non-alphanumeric characters from passed in NOID
    noid_id = params[:id]&.gsub(/[^A-Za-z0-9]/, '')

    # If cleaned NOID is valid, redo the request. Otherwise raise error.
    if noid_service.valid?(noid_id)
      redirect_to(request.parameters.merge(id: noid_id))
    else
      raise ActiveFedora::ObjectNotFoundError
    end
  end
end
