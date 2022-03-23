# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

require 'avalon/variations_timeline_importer'

class TimelinesController < ApplicationController
  before_action :authenticate_user!, except: [:show, :manifest, :timeliner]
  load_and_authorize_resource except: [:import_variations_timeline, :duplicate, :show, :index, :timeliner, :manifest]
  load_resource only: [:show, :manifest]
  authorize_resource only: [:index]
  before_action :user_timelines, only: [:index, :paged_index]
  before_action :all_other_timelines, only: [:edit]
  before_action :load_timeline_token, only: [:show, :duplicate, :manifest]
  skip_before_action :verify_authenticity_token, only: [:create, :manifest_update]

  helper_method :access_token_url

  # POST /timelines/import_variations_timeline
  def import_variations_timeline
    timeline_file = params[:Filedata]
    timeline = Avalon::VariationsTimelineImporter.new.import_timeline(timeline_file, current_user)
    if timeline.persisted?
      redirect_to timeline, notice: 'Variations timeline was successfully imported.'
    else
      redirect_to timelines_url, flash: { error: "Import failed: #{timeline.error_messages}" }
    end
  rescue StandardError => e
    redirect_to timelines_url, flash: { error: "Import failed: #{e.message} #{e.backtrace}" }
  end

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
                                              class: 'copy-timeline-button btn btn-sm btn-outline') do
          "<i class='fa fa-clone' aria-hidden='true'></i> Copy".html_safe
        end
        edit_button = view_context.link_to(edit_timeline_path(timeline), class: 'btn btn-sm btn-outline') do
          "<i class='fa fa-edit' aria-hidden='true'></i> Edit Details".html_safe
        end
        delete_button = view_context.link_to(timeline_path(timeline), method: :delete, class: 'btn btn-sm btn-danger btn-confirmation', data: { placement: 'bottom' }) do
          "<i class='fa fa-times' aria-hidden='true'></i> Delete".html_safe
        end
        [
          view_context.link_to(timeline.title, timeline_path(timeline), title: timeline.description),
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
        url_fragment = "noHeader=true&noFooter=true&noSourceLink=false"
        if current_user == @timeline.user
          url_fragment += "&resource=#{Addressable::URI.escape_component(manifest_timeline_url(@timeline, format: :json), '://?=')}"
          url_fragment += "&callback=#{Addressable::URI.escape_component(manifest_timeline_url(@timeline, format: :json), '://?=')}"
        elsif current_user
          url_fragment += "&resource=#{Addressable::URI.escape_component(manifest_timeline_url(@timeline, format: :json, token: @timeline.access_token), '://?=')}"
          url_fragment += "&callback=#{Addressable::URI.escape_component(timelines_url, '://?=')}"
        end
        @timeliner_iframe_url = timeliner_path + "##{url_fragment}"
      end
      format.json do
        render json: @timeline
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
    respond_to do |format|
      format.json do
        if timeline_params.blank?
          # Accept raw IIIF manifest here from timeliner tool
          manifest = request.body.read
          # Determine source from first content resource
          manifest_json = JSON.parse(manifest)
          stream_url = manifest_json["items"][0]["items"][0]["items"][0]["body"]["id"]
          # Only handles urls like "https://spruce.dlib.indiana.edu/master_files/6108vd10d/auto.m3u8#t=0.0,3437.426"
          _, master_file_id, media_fragment = stream_url.match(/master_files\/(.*)\/.*t=(.*)/).to_a
          source = master_file_url(id: master_file_id) + "?t=#{media_fragment}"
          @timeline = Timeline.new(user: current_user, manifest: manifest, source: source)
        else
          @timeline = Timeline.new(timeline_params.merge(user: current_user))
        end

        if @timeline.save
          # When create is successful for cloned timelines, a redirect to the new timeline will be handled by the browser
          render json: @timeline, status: :created, location: @timeline
        else
          render json: @timeline.errors, status: :unprocessable_entity
        end
      end
      format.html do
        @timeline = Timeline.new(timeline_params.merge(user: current_user))
        if @timeline.save
          # If requested, add initial structure to timeline manifest
          initialize_structure! if params[:include_structure].present?
          redirect_to @timeline
        else
          flash.now[:error] = @timeline.errors.full_messages.to_sentence
          render :new
        end
      end
    end
  end

  # PATCH/PUT /timelines/1
  # PATCH/PUT /timelines/1.json
  def update
    respond_to do |format|
      format.json do
        if @timeline.update(timeline_params)
          render json: @timeline, status: :created, location: @timeline
        else
          render json: @timeline.errors, status: :unprocessable_entity
        end
      end
      format.html do
        if @timeline.update(timeline_params)
          redirect_to edit_timeline_path(@timeline), notice: 'Timeline was successfully updated.'
        else
          flash.now[:error] = "There are errors with your submission.  #{@timeline.errors.full_messages.join(', ')}"
          render :edit
        end
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

  # GET /timelines/1/manifest.json
  def manifest
    authorize! :read, @timeline
    respond_to do |format|
      format.json do
        render json: @timeline.manifest
      end
    end
  end

  # POST /timelines/1/manifest.json
  def manifest_update
    respond_to do |format|
      format.json do
        # Accept raw IIIF manifest here from timeliner tool
        @timeline.manifest = request.body.read
        if @timeline.save
          render json: @timeline.manifest, status: :created, location: @timeline
        else
          render json: @timeline.errors, status: :unprocessable_entity
        end
      end
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

  def timeliner
    render layout: false
  end

  private

    def initialize_structure!
      mf = MasterFile.find timeline_params[:source].split('?t=')[0].split('/').last
      structure = mf.structuralMetadata.content
      return unless structure.present?
      structure = Nokogiri::XML.parse(structure)
      duration = mf.duration.to_f / 1000
      starttime, endtime = view_context.parse_media_fragment(timeline_params[:source].split('?t=')[1])
      starttime ||= 0.0
      endtime ||= duration
      structures = []
      topnode = structure.xpath('//Item')
      topnode.children.reject(&:blank?).each do |n|
        range = parse_timeline_node(n, starttime, endtime, duration)
        structures << range if range.present?
      end

      # pad ends of timeline if structure doesn't align
      # when custom scope is specified avoiding overlapping the existing timespans in structure
      # structures array is empty
      structure_start = min_range(structures) || starttime
      structure_end = max_range(structures) || endtime
      structures = [timeline_canvas('', 0, structure_start)] + structures if structure_start.positive?
      structures += [timeline_canvas('', structure_end, endtime - starttime)] if structure_end < endtime - starttime
      manifest = JSON.parse(@timeline.manifest)
      manifest['structures'] = structures
      @timeline.manifest = manifest.to_json
      @timeline.save
    end

    def min_range(structures)
      return if structures.empty?
      first = structures.first
      if canvas_range?(first)
        view_context.parse_hour_min_sec(first[:items][0][:id].split('t=')[1].split(',')[0])
      else
        min_range(first[:items])
      end
    end

    def max_range(structures)
      return if structures.empty?
      last = structures.last
      if canvas_range?(last)
        view_context.parse_hour_min_sec(last[:items][0][:id].split('t=')[1].split(',')[1])
      else
        max_range(last[:items])
      end
    end

    def parse_timeline_node(node, startlimit, endlimit, duration)
      if node.name == 'Div'
        range = timeline_range(node.attribute('label')&.value || '')
        node.children.reject(&:blank?).each do |n|
          newnode = parse_timeline_node(n, startlimit, endlimit, duration)
          range[:items] << newnode if newnode.present?
        end
        # don't add parent ranges that only have one child, instead add child only
        if range[:items].present?
          range[:items].length == 1 && canvas_range?(range[:items][0]) ? range[:items][0] : range
        end
      elsif node.name == 'Span'
        spanbegin = view_context.parse_hour_min_sec(node.attribute('begin')&.value || '0')
        spanend = view_context.parse_hour_min_sec(node.attribute('end')&.value || duration.to_s)
        # startlimit <= span <= endlimit condition picks up spans enclosed  within the specified range
        # this sometimes returns an empty structure when a custom scope is given
        timeline_canvas(node.attribute('label')&.value || '', spanbegin - startlimit, spanend - startlimit) if spanbegin >= startlimit && spanend <= endlimit
      end
    end

    def timeline_range(label)
      {
        'id': "id-#{SecureRandom.uuid}",
        'type': 'Range',
        'label': { 'en': [label] },
        'items': []
      }
    end

    def timeline_canvas(label, starttime, endtime)
      range = timeline_range(label)
      canvas = {
        'type': 'Canvas',
        'id': "#{timeline_url(@timeline)}/manifest/canvas#t=#{starttime},#{endtime}"
      }
      range[:items] = [canvas]
      range
    end

    def canvas_range?(range)
      range[:items].length == 1 && range[:items][0][:type] == 'Canvas'
    end

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
      new_params = params.fetch(:timeline, {}).permit(:title, :visibility, :description, :access_token, :tags, :source, :manifest, :include_structure)
      new_params[:tags] = JSON.parse(new_params[:tags]) if new_params[:tags].present?
      new_params
    end
end
