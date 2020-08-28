# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

class ObjectsController < ApplicationController
  def show
    obj = fetch_object params[:id]
    if obj.blank?
      redirect_to root_path
    else
      if params[:urlappend]
        url = URI.join(polymorphic_url(obj)+'/', params[:urlappend].sub(/^[\/]/,''))
      else
        url = URI(polymorphic_url(obj))
      end

      newparams = params.except(:controller, :action, :id, :urlappend)
      url.query = newparams.permit!.to_query if newparams.present?
      redirect_to url.to_s
    end
  end

  def autocomplete
    expires_now
    model = Module.const_get(params[:t].to_s.classify)
    render json: model.send(:autocomplete, params[:q].strip)
  end

end
