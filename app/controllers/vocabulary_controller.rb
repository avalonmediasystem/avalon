# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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
  before_action :authenticate_user!
  authorize_resource class: Avalon::ControlledVocabulary
  respond_to :json

  before_action :verify_vocabulary_exists, except: [:index]

  def index
    render json: Avalon::ControlledVocabulary.vocabulary
  end

  def show
    render json: Avalon::ControlledVocabulary.vocabulary[params[:id].to_sym]
  end

  def update
    unless params[:entry].present?
      render json: {errors: ["No update value sent"]}, status: 422 and return
    end

    @v = Avalon::ControlledVocabulary.vocabulary
    begin
      build_update(@v)
    rescue NoMethodError
      render json: {errors: ["Update failed. Ensure that the new entry is in the proper form for the intended vocabulary."]}, status: 422 and return
    end
    result = Avalon::ControlledVocabulary.vocabulary = @v
    if result
      head :ok, content_type: 'application/json'
    else
      render json: {errors: ["Update failed"]}, status: 422
    end
  end

  private

  def verify_vocabulary_exists
    if Avalon::ControlledVocabulary.vocabulary[params[:id].to_sym].blank?
      render json: {errors: ["Vocabulary not found for #{params[:id]}"]}, status: 404
    end
  end

  def build_update(vocabulary)
    if vocabulary_params[:entry].is_a?(ActionController::Parameters)
      new_entry = vocabulary_params[:entry].to_hash
      @v[params[:id].to_sym].merge!(new_entry)
    else
      @v[params[:id].to_sym] |= Array(params[:entry])
    end
  end

  def vocabulary_params
    params.permit(entry: {})
  end
end
