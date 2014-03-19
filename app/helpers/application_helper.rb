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

  def share_link_for(obj)
    if obj.nil?
      I18n.t('media_object.empty_share_link')
    elsif obj.permalink.present?
      obj.permalink
    else
      case obj
      when MediaObject then media_object_url(obj)
      when MasterFile  then pid_section_media_object_url(obj.mediaobject.pid, obj.pid)
      end
    end
  end

  def image_for(document)
    master_file_id = document[:section_pid_tesim].try :first
    
    video_count = document[:mods_tesim].count{|m| m.start_with?('moving image') }
    audio_count = document[:mods_tesim].count{|m| m.start_with?('sound recording') }

    if master_file_id
      if video_count > 0
        thumbnail_master_file_path(master_file_id)
      else
        asset_path('audio_icon.png')
      end
    else
      if video_count > 0 && audio_count > 0
        asset_path('hybrid_icon.png')
      elsif video_count > audio_count
        asset_path('video_icon.png')
      elsif audio_count > video_count
        asset_path('audio_icon.png')
      else
        nil
      end
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

  def search_result_label item
    if item['title_tesim'].present?
      label = truncate(item['title_tesim'].first, length: 100)
    else
      label = item.id
    end
    
    if item['duration_tesim'].present?
      duration = item['duration_tesim'].first
      if duration.respond_to?(:to_i) && duration.to_i > 0
        label += " (#{milliseconds_to_formatted_time(duration.to_i)})"
      end
    end

    label
  end

  def stream_label_for(resource)
    if resource.label.present?
      resource.label
    elsif resource.file_location.present?
      File.basename(resource.file_location)
    else
      resource.pid
    end
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

  def vgroup_display value
    c = Course.find_by_context_id(value)
    c.nil? ? value : (c.title || c.label || value)
  end

  def truncate_center label, output_label_length, end_length = 0
    end_length = start_length / 2 if end_length == 0
    truncate(label , length: output_label_length, 
      omission: "...#{label.last(end_length)}")
  end
end
