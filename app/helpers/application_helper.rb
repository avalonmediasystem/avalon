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


module ApplicationHelper
  def application_name
    Avalon::Configuration.lookup('name') || 'Avalon Media System'
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
    master_file_id = document["section_pid_tesim"].try :first

    video_count = document["avalon_resource_type_tesim"].count{|m| m.start_with?('moving image') } rescue 0
    audio_count = document["avalon_resource_type_tesim"].count{|m| m.start_with?('sound recording') } rescue 0

    if master_file_id
      if video_count > 0
        thumbnail_master_file_path(master_file_id)
      elsif audio_count > 0
        asset_path('audio_icon.png')
      else
        nil
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

  def avalon_image_tag(document, image_options)
    image_url = image_for(document)
    if image_url.present?
      link_to(media_object_path(document[:id]), {class: 'result-thumbnail'}) do
        image_tag(image_url)
      end
    else
      image_tag 'no_icon.png', class: 'result-thumbnail'
    end
  end

  def display_metadata(label, value, default=nil)
    return if value.blank? and default.nil?
    sanitized_values = Array(value).collect { |v| sanitize(v.to_s.strip) }.delete_if(&:empty?)
    sanitized_values = Array(default) if sanitized_values.empty?
    label = label.pluralize(sanitized_values.size)
    result = content_tag(:dt, label) +
    content_tag(:dd) {
      safe_join(sanitized_values,'; ')
    }
  end

  def search_result_label item
    if item['title_tesi'].present?
      label = truncate(item['title_tesi'], length: 100)
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
  
  # display millisecond times in HH:MM:SS format
  # @param [Float] milliseconds the time to convert
  # @return [String] time in HH:MM:SS
  def pretty_time( milliseconds )
    duration = milliseconds/1000
    Time.at(duration).utc.strftime(duration<3600?'%M:%S':'%H:%M:%S')
  end

  def git_commit_info pattern="%s %s [%s]"
    begin
      repo = Grit::Repo.new(Rails.root)
      branch = repo.head.name
      commit = repo.head.commit.sha[0..5]
      time = repo.head.commit.committed_date.strftime('%d %b %Y %H:%M:%S')
      link_to_if(AboutPage.configuration.git_log, pattern % [branch,commit,time], about_page.component_path('git_log'))
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
    end_length = output_label_length / 2 - 3 if end_length == 0
    truncate(label, length: output_label_length,
      omission: "...#{label.last(end_length)}")
  end

  def master_file_meta_properties( m )
    formatted_duration = m.duration ? Duration.new(m.duration.to_i / 1000).iso8601 : ''
    item_type = m.is_video? ? 'http://schema.org/VideoObject' : 'http://schema.org/AudioObject'

    content_tag(:div, itemscope: '', itemprop:  m.is_video? ? 'video' : 'audio',  itemtype: item_type ) do
      concat tag(:meta, itemprop: 'name', content: m.mediaobject.title )
      concat tag(:meta, itemprop: 'duration', content: formatted_duration )
      concat tag(:meta, itemprop: 'thumbnail', content: thumbnail_master_file_url(m))
      concat tag(:meta, itemprop: 'image', content: poster_master_file_url(m))
      concat tag(:meta, itemprop: 'sameAs', content: m.permalink ) if m.permalink.present?
      concat tag(:meta, itemprop: 'genre', content: m.mediaobject.genre.join(' ')) unless m.mediaobject.genre.empty?
      concat tag(:meta, itemprop: 'about', content: m.mediaobject.subject.join(' ')) unless m.mediaobject.subject.empty?
      concat tag(:meta, itemprop: 'description', content: m.mediaobject.abstract) if m.mediaobject.abstract.present?
      yield
    end
  end
end
