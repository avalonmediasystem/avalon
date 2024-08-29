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


module ApplicationHelper
  def application_name
    Settings.name || 'Avalon Media System'
  end

  def release_text
    "#{application_name} #{t(:release_label)} #{Avalon::VERSION}"
  end

  def share_link_for(obj, only_path: false)
    if obj.nil?
      I18n.t('media_object.empty_share_link')
    elsif obj.permalink.present?
      obj.permalink
    else
      case obj
      when MediaObjectBehavior
        if only_path
          media_object_path(obj)
        else
          media_object_url(obj)
        end
      when MasterFileBehavior
        if only_path
          id_section_media_object_path(obj.media_object_id, obj.id)
        else
          id_section_media_object_url(obj.media_object_id, obj.id)
        end
      end
    end
  end

  def lti_share_url_for(obj, _opts = {})
    if obj.nil? || Avalon::Authentication::Providers.none? { |p| p[:provider] == :lti }
      return I18n.t('share.empty_lti_share_url')
    end
    target = case obj
             when MediaObjectBehavior then obj.id
             when MasterFileBehavior then obj.id
             when Playlist then obj.to_gid_param
             when Timeline then obj.to_gid_param
             end
    user_omniauth_callback_lti_url(target_id: target)
  end

  def image_for(document)
    master_file_id = document["section_id_ssim"].try :first

    video_count = document["avalon_resource_type_ssim"].count{|m| m.downcase.start_with?('moving image') } rescue 0
    audio_count = document["avalon_resource_type_ssim"].count{|m| m.downcase.start_with?('sound recording') } rescue 0

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
    link_to(media_object_path(document[:id]), {class: 'result-thumbnail'}) do
      image_url.present? ? image_tag(image_url) : image_tag('no_icon.png')
    end
  end

  def display_metadata(label, value, default=nil)
    sanitized_values = Array(value).collect { |v| sanitize(v.to_s.strip) }.delete_if(&:empty?)
    return if sanitized_values.empty? and default.nil?
    sanitized_values = Array(default) if sanitized_values.empty?
    label = label.pluralize(sanitized_values.size)
    contents = content_tag(:dd) do
      content_tag(:pre) { safe_join(sanitized_values, '; ') }
    end
    content_tag(:dt, label) + contents
  end

  def display_has_caption_or_transcript value
    value = value == "true" ? 'Yes' : 'No'
  end

  def search_result_label item
    if item['title_tesi'].present?
      label = truncate(item['title_tesi'], length: 100)
    else
      label = item[:id]
    end

    if item['duration_ssi'].present?
      duration = item['duration_ssi']
      if duration.respond_to?(:to_i) && duration.to_i > 0
        label += " (#{milliseconds_to_formatted_time(duration.to_i, false)})"
      end
    end

    label
  end

  def stream_label_for(resource)
    if resource.title.present?
      resource.title
    elsif resource.file_location.present?
      File.basename(resource.file_location)
    else
      resource.id
    end
  end

  #Taken from Hydra::Controller::ControllerBehavior
  def user_key
    current_user.user_key if current_user
  end

  # We are converting FFprobe's duration output to milliseconds for
  # uniformity with existing metadata and consequently leaving these
  # conversion methods in place for now.
  def milliseconds_to_formatted_time(milliseconds, include_fractions = true)
    total_seconds = milliseconds / 1000
    hours = total_seconds / (60 * 60)
    minutes = (total_seconds / 60) % 60
    seconds = total_seconds % 60
    fractional_seconds = milliseconds.to_s[-3, 3].to_i
    fractional_seconds = (include_fractions && fractional_seconds.positive? ? ".#{fractional_seconds}" : '')

    output = ''
    if hours > 0
      output += "#{hours}:"
    end

    output += "#{minutes.to_s.rjust(2,'0')}:#{seconds.to_s.rjust(2,'0')}#{fractional_seconds}"
    output
  end

  # display millisecond times in HH:MM:SS.sss format
  # @param [Float] milliseconds the time to convert
  # @return [String] time in HH:MM:SS.sss
  def pretty_time(milliseconds)
    milliseconds = Float(milliseconds).to_int # will raise TypeError or ArgumentError if unparsable as a Float
    return "00:00:00.000" if milliseconds <= 0

    total_seconds = milliseconds / 1000.0
    hours = (total_seconds / (60 * 60)).to_i.to_s.rjust(2, "0")
    minutes = ((total_seconds / 60) % 60).to_i.to_s.rjust(2, "0")
    seconds = (total_seconds % 60).to_i.to_s.rjust(2, "0")
    frac_seconds = (milliseconds % 1000).to_s.rjust(3, "0")[0..2]
    hours + ":" + minutes + ":" + seconds + "." + frac_seconds
  end

  FLOAT_PATTERN = Regexp.new(/^\d+([.]\d*)?$/).freeze

  def parse_hour_min_sec(s)
    return nil if s.nil?
    smh = s.split(':').reverse
    (0..2).each do |i|
      smh[i] = FLOAT_PATTERN.match?(smh[i]) ? Float(smh[i]) : 0
    end
    smh[0] + (60 * smh[1]) + (3600 * smh[2])
  end

  def parse_media_fragment(fragment)
    return 0, nil unless fragment.present?
    f_start, f_end = fragment.split(',')
    [parse_hour_min_sec(f_start), parse_hour_min_sec(f_end)]
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
      v.is_a?(Array) ? v.collect { |v1| [k, Addressable::URI.escape(v1.to_s)].join('=') } : [k, Addressable::URI.escape(v.to_s)].join('=')
    end.flatten.join('&')
    ActiveFedora.solr.conn.uri.merge("select?#{qs}").to_s.html_safe
  end

  def vgroup_display value
    c = Course.find_by_context_id(value)
    c.nil? ? value : (c.title || c.label || value)
  end

  def truncate_center label, output_label_length, end_length = 0
    end_length = output_label_length / 2 - 3 if end_length == 0
    end_length = 0 if end_length.negative?
    truncate(label, length: output_label_length,
      omission: "...#{label.last(end_length)}")
  end

  def titleize value
    value.is_a?(Array) ? value.map(&:titleize) : value.titleize
  end

  def master_file_meta_properties( m )
    formatted_duration = m.duration ? Time.new(m.duration.to_i / 1000).iso8601 : ''
    item_type = m.is_video? ? 'http://schema.org/VideoObject' : 'http://schema.org/AudioObject'

    content_tag(:div, itemscope: '', itemprop:  m.is_video? ? 'video' : 'audio',  itemtype: item_type ) do
      concat tag(:meta, itemprop: 'name', content: m.media_object.title )
      concat tag(:meta, itemprop: 'duration', content: formatted_duration )
      concat tag(:meta, itemprop: 'thumbnail', content: thumbnail_master_file_url(m))
      concat tag(:meta, itemprop: 'image', content: poster_master_file_url(m))
      concat tag(:meta, itemprop: 'sameAs', content: m.permalink ) if m.permalink.present?
      concat tag(:meta, itemprop: 'genre', content: m.media_object.genre.join(' ')) unless m.media_object.genre.empty?
      concat tag(:meta, itemprop: 'about', content: m.media_object.subject.join(' ')) unless m.media_object.subject.empty?
      concat tag(:meta, itemprop: 'description', content: m.media_object.abstract) if m.media_object.abstract.present?
      yield
    end
  end

  def parent_layout(layout)
    @view_flow.set(:layout, output_buffer)
    output = render(:file => "layouts/#{layout}")
    self.output_buffer = ActionView::OutputBuffer.new(output)
  end

  def object_supplemental_file_path(object, file)
    if object.is_a?(MasterFile) || object.try(:model) == MasterFile
      master_file_supplemental_file_path(master_file_id: object.id, id: file.id)
    elsif object.is_a? MediaObject || object.try(:model) == MediaObject
      media_object_supplemental_file_path(media_object_id: object.id, id: file.id)
    else
      nil
    end
  end

  def object_supplemental_files_path(object)
    if object.is_a?(MasterFile) || object.try(:model) == MasterFile
      master_file_supplemental_files_path(object.id)
    elsif object.is_a? MediaObject || object.try(:model) == MediaObject
      media_object_supplemental_files_path(object.id)
    else
      nil
    end
  end
end
