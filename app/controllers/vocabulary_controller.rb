# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

class VocabularyController < ApplicationController
  respond_to :json

  def index
    render json: Avalon::ControlledVocabulary.vocabulary
  end

  def show
    if Avalon::ControlledVocabulary.vocabulary.has_key? params[:id].to_sym
      render json: Avalon::ControlledVocabulary.vocabulary[params[:id].to_sym]
    else
      render json: {errors: ["Vocabulary not found for #{params[:id]}"]}, status: 404
    end
  end

  def update
    result = false
    if Avalon::ControlledVocabulary.vocabulary.has_key? params[:id].to_sym
      if params[:entry].present?
        v = Avalon::ControlledVocabulary.vocabulary
        v[params[:id].to_sym] |= Array(params[:entry])
        result = Avalon::ControlledVocabulary.vocabulary = v
        if result
          render nothing: true, content_type: 'application/json', status: 200
        else
          render json: {errors: ["Update failed"]}, status: 422
        end
      else
        render json: {errors: ["No update value sent"]}, status: 422
      end
    else
      render json: {errors: ["Vocabulary not found for #{params[:id]}"]}, status: 404
    end
  end

end
