# frozen_string_literal: true

# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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

class TimelinesController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  load_and_authorize_resource except: [:import_variations_timeline, :duplicate, :show, :index]
  load_resource only: [:show]
  authorize_resource only: [:index]
  before_action :user_timelines, only: [:index, :paged_index]
  before_action :all_other_timelines, only: [:edit]
  before_action :load_timeline_token, only: [:show, :duplicate]

  helper_method :access_token_url

  # POST /timelines/paged_index
  def paged_index
    # Timelines for index page are loaded dynamically by jquery datatables javascript which
    # requests the html for only a limited set of rows at a time.
    records_total = @timelines.count
    columns = ['title', 'description', 'visibility', 'updated_at', 'tags', 'actions']

    # Filter title
    title_filter = params['search']['value']
    @timelines = @timelines.title_like(title_filter) if title_filter.present?

    # Apply tag filter if requested
    tag_filter = params['columns']['4']['search']['value']
    @timelines = @timelines.with_tag(tag_filter) if tag_filter.present?
    timelines_filtered_total = @timelines.count

    sort_column = params['order']['0']['column'].to_i rescue 0
    sort_direction = params['order']['0']['dir'] rescue 'asc'
    session[:timeline_sort] = [sort_column, sort_direction]
    @timelines = @timelines.order(columns[sort_column].downcase => sort_direction)
    @timelines = @timelines.offset(params['start']).limit(params['length'])
    response = {
      "draw": params['draw'],
      "recordsTotal": records_total,
      "recordsFiltered": timelines_filtered_total,
      "data": @timelines.collect do |timeline|
        copy_button = view_context.button_tag(type: 'button',
                                              data: { timeline: timeline },
                                              class: 'copy-timeline-button btn btn-default btn-xs') do
          "<i class='fa fa-clone' aria-hidden='true'></i> Copy".html_safe
        end
        edit_button = view_context.link_to(edit_timeline_path(timeline), class: 'btn btn-default btn-xs') do
          "<i class='fa fa-edit' aria-hidden='true'></i> Edit Details".html_safe
        end
        delete_button = view_context.link_to(timeline_path(timeline), method: :delete, class: 'btn btn-xs btn-danger btn-confirmation', data: { placement: 'bottom' }) do
          "<i class='fa fa-times' aria-hidden='true'></i> Delete".html_safe
        end
        [
          view_context.link_to(timeline.title, timeline_path(timeline), title: timeline.description, target: "blank"),
          timeline.description,
          view_context.timeline_human_friendly_visibility(timeline.visibility),
          "<span title='#{timeline.updated_at.utc.iso8601}'>#{view_context.time_ago_in_words(timeline.updated_at)} ago</span>",
          timeline.tags.present? ? timeline.tags.join(', ') : '',
          "#{copy_button} #{edit_button} #{delete_button}"
        ]
      end
    }
    respond_to do |format|
      format.json do
        render json: response
      end
    end
  end

  # GET /timelines/1
  # GET /timelines/1.json
  def show
    authorize! :read, @timeline
    respond_to do |format|
      format.html do
        url_fragment = "resource=#{URI.escape(timeline_url(@timeline, format: :json, token: @timeline.access_token), '://?=')}"
        # # TODO: determine if need to clone timeline and provide saveback url specific to current_user
        # if current_user == @timeline.user
        #   url_fragment += "&save=#{URI.escape(timeline_url(@timeline, format: :json))}"
        # end
        redirect_to Settings.timeliner.timeliner_url + "##{url_fragment}"
      end
      format.json do
        render json: @timeline.manifest
      end
    end
  end

  # GET /timelines/new
  def new
    @timeline = Timeline.new
  end

  # POST /timelines
  # POST /timelines.json
  def create
    # TODO: Accept raw IIIF manifest here from timeliner tool?
    @timeline = Timeline.new(timeline_params.merge(user: current_user))

    respond_to do |format|
      if @timeline.save
        format.html { redirect_to @timeline }
        format.json { render json: @timeline, status: :created, location: @timeline }
      else
        format.html do
          flash.now[:error] = @timeline.errors.full_messages.to_sentence
          render :new
        end
        format.json { render json: @timeline.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /timelines/1
  # PATCH/PUT /timelines/1.json
  def update
    # TODO: Accept raw IIIF manifest here from timeliner tool
    respond_to do |format|
      if @timeline.update(timeline_params)
        format.html { redirect_to edit_timeline_path(@timeline), notice: 'Timeline was successfully updated.' }
        format.json { render json: @timeline, status: :created, location: @timeline }
      else
        format.html { render :edit }
        format.json { render json: @timeline.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /timelines/1
  # DELETE /timelines/1.json
  def destroy
    @timeline.destroy
    respond_to do |format|
      format.html { redirect_to timelines_url, notice: 'Timeline was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # POST /timelines
  def duplicate
    old_timeline = Timeline.find(params['old_timeline_id'])
    unless can? :duplicate, old_timeline
      render json: { errors: 'You do not have sufficient privileges to copy this item' }, status: 401 && return
    end
    @timeline = Timeline.new(timeline_params.merge(user: current_user, source: old_timeline.source, manifest: old_timeline.manifest, tags: old_timeline.tags))

    respond_to do |format|
      if @timeline.save
        format.json { render json: { timeline: @timeline, path: edit_timeline_path(@timeline) } }
      else
        format.json { render json: @timeline.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /timelines/1/regenerate_access_token
  def regenerate_access_token
    @timeline.access_token = nil
    @timeline.save!
    render json: { access_token_url: access_token_url(@timeline) }
  end

  def access_token_url(timeline)
    timeline_url(timeline, token: timeline.access_token)
  end

  private

    def user_timelines
      @timelines = Timeline.by_user(current_user)
    end

    def all_other_timelines
      @timelines = Timeline.by_user(current_user).where.not(id: @timeline)
    end

    def load_timeline_token
      @timeline_token = params[:token]
      current_ability.options[:timeline_token] = @timeline_token
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def timeline_params
      new_params = params.require(:timeline).permit(:title, :user_id, :visibility, :description, :access_token, :tags, :source, :manifest)
      new_params[:tags] = JSON.parse(new_params[:tags]) if new_params[:tags].present?
      new_params
    end
end
