# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

module ApplicationHelper
  def application_name
    'Avalon'
  end
  
  def release_text
    "#{application_name} #{t(:release_label)} #{Avalon::VERSION}"
  end

  def image_for(item_id)
    #TODO index the thumbnail url to avoid having to hit fedora to get it
    media_object = MediaObject.find(item_id)
    masterfile = media_object.parts.first 

    imageurl = thumbnail_master_file_path(masterfile) unless masterfile.nil? or masterfile.thumbnail.new?

    video_count = 0
    audio_count = 0
    media_object.parts.each do |part|
      video_count = video_count + 1 if "Moving image" == part.file_format
      audio_count = audio_count + 1 if "Sound" == part.file_format
    end

    logger.debug "<< Object has #{video_count} videos and #{audio_count} audios >>"
    imageurl ||= case
                 when (video_count > 0 and 0 == audio_count)
                   "video_icon.png"
                 when (audio_count > 0 and 0 == video_count)
                   "audio_icon.png"
                 when (video_count > 0 and audio_count > 0)
                   # TODO
                   # We need to test if both audio and video are present
                   # instead of assuming when there is more than one part
                   "hybrid_icon.png" 
                 else
                   nil
                 end
  end

  # Creates a hot link to the downloadable file if it is available. File names longer
  # than 25 characters are truncated although this can be overridden by passing in a
  # different value
  def file_download_label(masterfile)
    # Check to see if the file name is longer than 25 characters
    if 20 > masterfile.descMetadata.title[0].length 
      label_display = masterfile.descMetadata.title[0]
    else
      label_display = truncate(masterfile.descMetadata.title[0], length: 15)
      label_display << "."
      label_display << masterfile.descMetadata.title[0].split('.').last
    end
  end

  def display_metadata(label, value, default=nil)
    return if value.blank? and default.nil?
    value ||= default
    sanitized_values = Array(value).collect { |v| sanitize(v.to_s.strip) }.delete_if(&:empty?)
    label = label.pluralize(sanitized_values.size)
    result = content_tag(:dt, label) +
    content_tag(:dd) {
      sanitized_values.join('; ')
    }
  end

  # def display_metadata(label, value, default=nil)
  #   return if value.blank? and default.nil?
  #   value ||= default
  #   sanitized_values = Array(value).collect { |v| sanitize(v.to_s.strip) }.delete_if(&:empty?)
  #   label = label.pluralize(sanitized_values.size)
  #   label_value_pair = label + ': ' + sanitized_values.join('; ')
  #   result = content_tag(:li, label_value_pair)
  # end

  #FIXME
  #This helper should be used by blacklight to display the "Title" field in search results
  def search_result_label item
    label = item.id
    unless item["title_sim"].blank?
      label = truncate(item["title_sim"], length: 100)
    end
    
    if ! item['duration_tesim'].nil? && ! item['duration_tesim'].empty? 
      item_duration = item['duration_tesim'].first
      if item_duration.respond_to?(:to_i)
        formatted_duration = milliseconds_to_formatted_time(item_duration.to_i)
        label += " (#{formatted_duration})"
      end
    end

    label
  end

  def stream_label_for(resource)
    label = ''
    
    unless resource.nil?
      if resource.label.blank?
        label = File.basename(resource.file_location)
      else
        label = resource.label
      end
    end
    label
  end

  #Taken from Hydra::Controller::ControllerBehavior
  def user_key
    current_user.user_key if current_user
  end

  # the mediainfo gem returns duration as milliseconds
  # see attr_reader.rb line 48 in the mediainfo source
  def milliseconds_to_formatted_time( milliseconds )
    total_seconds = milliseconds / 1000                                     
    hours = total_seconds / (60 * 60)
    minutes = (total_seconds / 60) % 60
    seconds = total_seconds % 60

    output = ''
    if hours > 0
      output += "#{hours}:"
    end

    output += "#{minutes.to_s.rjust(2,'0')}:#{seconds.to_s.rjust(2,'0')}"
    output
  end
  
  def link_to_add_dynamic_field( name, opts = {} )
    opts.merge!( class: 'add-dynamic-field btn btn-mini' )
    link_to name, '#', opts
  end

  def git_commit_info pattern="%s %s [%s]"
    begin
      repo = Grit::Repo.new(Rails.root)
      branch = repo.head.name
      commit = repo.head.commit.sha[0..5]
      time = repo.head.commit.committed_date.strftime('%d %b %Y %H:%M:%S')
      pattern % [branch,commit,time]
    rescue
      ""
    end
  end

  def active_for_controller controller_name
    params[:controller] == controller_name.to_s ? 'active' : ''
  end

  def build_solr_request_from_response
    qs = @response['responseHeader']['params'].reject { |k,v| k == 'wt' }.collect do |k,v|
      v.is_a?(Array) ? v.collect { |v1| [k,URI.encode(v1.to_s)].join('=') } : [k,URI.encode(v.to_s)].join('=')
    end.flatten.join('&')
    ActiveFedora.solr.conn.uri.merge("select?#{qs}").to_s.html_safe
  end
end
