# Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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

module MediaObjectsHelper
      # Quick and dirty solution to the problem of displaying the right template.
      # Quick and dirty also gets it done faster.
      def current_step_for(status=nil)
        if status.nil?
          status = HYDRANT_STEPS.first
        end

        HYDRANT_STEPS.template(status)
      end

      # Based on the current context it will choose which class should be
      # applied to the display. If you are not using Twitter Bootstrap or
      # want different defaults then change them here.
      #
      # The context here is the media_object you are working with.
      def class_for_step(context, step)
        css_class = case
          # when context.workflow.current?(step)
          #   'nav-info'
          when context.workflow.completed?(step)
            'nav-success'
          else 'nav-disabled'
          end

        css_class
     end

      def form_id_for_step(step)
        "#{step.gsub('-','_')}_form"
      end

      def dropbox_url collection
         ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
         path = URI::Parser.new.escape(collection.dropbox_directory_name || "", %r{[/\\%& #]})
         url = File.join(Settings.dropbox.upload_uri, path)
         ic.iconv(url)
      end

      def combined_display_date media_object
        (issued,created) = case media_object
        when MediaObject
          [media_object.date_issued, media_object.date_created]
        when Hash
          [media_object[:document]['date_ssi'], media_object[:document]['date_created_ssi']]
        end
        result = issued
        result += " (Creation date: #{created})" if created.present?
        result
      end

      def display_other_identifiers media_object
        # bibliographic_id has form [:type,"value"], other_identifier has form [[:type,"value],[:type,"value"],...]
        ids = media_object.bibliographic_id.present? ? [media_object.bibliographic_id] : []
        ids += Array(media_object.other_identifier)
        ids.uniq.collect{|i| "#{ ModsDocument::IDENTIFIER_TYPES[i[:source]] }: #{ i[:id] }" }
      end

      def display_notes media_object
        note_string = ""
        note_types = ModsDocument::NOTE_TYPES.clone
        note_types['table of contents']='Contents'
        sorted_note_types = note_types.keys.sort
        sorted_note_types.prepend(sorted_note_types.delete 'general')
        sorted_note_types.each do |note_type|
          notes = note_type == 'table of contents'? media_object.table_of_contents : gather_notes_of_type(media_object, note_type)
          notes.each_with_index do |note, i|
            note_string += "<p class='item_note_header'>#{note_types[note_type]}</p>" if i==0 and note_type!='general'
            note_string += "<pre>#{note}</pre>"
          end
        end
        note_string
      end

      def gather_notes_of_type media_object, type
        media_object.note.present? ? media_object.note.select{|n| n[:type]==type}.collect{|n|n[:note]} : []
      end

      def display_language media_object
        media_object.language.collect{|l|l[:text]}.uniq
      end

      def display_related_item media_object
        media_object.related_item_url.collect{ |r| link_to( r[:label], r[:url]) }
      end

      def display_rights_statement media_object
        return nil unless media_object.rights_statement.present?
        label = ModsDocument::RIGHTS_STATEMENTS[media_object.rights_statement]
        return nil unless label.present?
        link = link_to label, media_object.rights_statement, target: '_blank'
        content_tag(:dt, 'Rights Statement') + content_tag(:dd) { link }
      end

      def current_quality stream_info
        available_qualities = Array(stream_info[:stream_flash]).collect {|s| s[:quality]}
        available_qualities += Array(stream_info[:stream_hls]).collect {|s| s[:quality]}
        available_qualities.uniq!
        quality ||= session[:quality] if session['quality'].present? && available_qualities.include?(session[:quality])
        quality ||= Settings.streaming.default_quality if available_qualities.include?(Settings.streaming.default_quality)
        quality ||= available_qualities.first
        quality
      end

      def is_current_section? section
         @currentStream && ( section.id == @currentStream.id )
      end

      def show_progress?(sections)
        encode_gids = sections.collect { |mf| "gid://ActiveEncode/#{mf.encoder_class}/#{mf.workflow_id}" }
        ActiveEncode::EncodeRecord.where(global_id: encode_gids).any? { |encode| encode.state.to_s.upcase != 'COMPLETED' }
      end

      def any_failed?(sections)
        encode_gids = sections.collect { |mf| "gid://ActiveEncode/#{mf.encoder_class}/#{mf.workflow_id}" }
        ActiveEncode::EncodeRecord.where(global_id: encode_gids).any? { |encode| encode.state.to_s.upcase == 'FAILED' }
      end

      def hide_sections? sections
        sections.blank? or (sections.length == 1 and !sections.first.has_structuralMetadata?)
      end

      def structure_html section, index, show_progress
        current = is_current_section? section
        progress_div = show_progress ? '<div class="status-detail alert" style="display: none"></div>' : ''
        playlist_btn = current_ability.can?(:create, Playlist) ? "<button type=\"button\" title=\"Add section to playlist\" aria-label=\"Add section to playlist\" class=\"structure_add_to_playlist outline_on btn btn-primary\" data-scope=\"master_file\" data-masterfile-id=\"#{section.id}\"></button>" : ''

        headeropen = <<EOF
       <div class="panel-heading" role="tab" id="heading#{index}" data-media-object-id="#{section.media_object_id}" data-section-id="#{section.id}">
       <h4 class="panel-title #{ 'progress-indented' if progress_div.present? }">
       #{playlist_btn}
EOF
        headerclose = <<EOF
       #{progress_div}
       </h4>
       </div>
EOF

        data = {
          segment: section.id,
          is_video: section.file_format != 'Sound',
          share_link: share_link_for(section),
          native_url: id_section_media_object_path(@media_object, section.id)
        }
        data[:lti_share_link] = user_omniauth_callback_lti_url(target_id: section) if Avalon::Authentication::Providers.any? {|p| p[:provider] == :lti }
        duration = section.duration.blank? ? '' : " (#{milliseconds_to_formatted_time(section.duration.to_i, false)})"

        # If there is no structural metadata associated with this master_file return the stream info
        unless section.has_structuralMetadata?
          label = "#{index+1}. #{stream_label_for(section)} #{duration}".html_safe
          link = link_to label, share_link_for( section ), id: 'section-title-' + section.id, data: data, class: 'playable wrap' + (current ? ' current-stream current-section' : '')
          return "#{headeropen}<ul><li class='stream-li'>#{link}</li></ul>#{headerclose}"
        end

        sectionnode = section.structuralMetadata.xpath('//Item')

        # If there are subsections within structure, build a collapsible panel with the contents
        if sectionnode.children.present?
          tracknumber = 0
          label = "#{index+1}. #{sectionnode.attribute('label').value} #{duration}".html_safe
          link = link_to label, share_link_for(section, only_path: true),
                         id: 'section-title-' + section.id, data: data,
                         class: 'playable wrap' + (current ? ' current-stream current-section' : '')
          wrapperopen = <<EOF
          #{headeropen}
          <button class="fa fa-minus-square #{current ? '' : 'hidden'}" data-toggle="collapse" data-target="#section#{index}" aria-expanded="#{current ? 'true' : 'false' }" aria-controls="collapse#{index}"></button>
          <button class="fa fa-plus-square #{current ? 'hidden' : ''}" data-toggle="collapse" data-target="#section#{index}" aria-expanded="#{current ? 'true' : 'false' }" aria-controls="collapse#{index}"></button>
          <ul><li>#{link}</li></ul>
          #{headerclose}

    <div id="section#{index}" class="panel-collapse collapse #{current ? 'in' : ''}" role="tabpanel" aria-labelledby="heading#{index}">
      <div class="panel-body">
        <ul>
EOF
          wrapperclose = <<EOF
        </ul>
      </div>
    </div>
EOF
        # If there are no subsections within the structure, return just the header with the single section
        else
          tracknumber = index
          wrapperopen = "#{headeropen}<ul>"
          wrapperclose = "</ul>#{headerclose}"
        end
        contents, tracknumber = parse_section section, sectionnode.first, tracknumber
        "#{wrapperopen}#{contents}#{wrapperclose}"
      end

      def parse_section section, node, index
        sectionnode = section.structuralMetadata.xpath('//Item')
        if sectionnode.children.present?
          tracknumber = 0
          contents = ''
          sectionnode.children.each do |node|
            next if node.blank?
            st, tracknumber = parse_node section, node, tracknumber
            contents+=st
          end
        else
          contents, tracknumber = parse_node section, sectionnode.first, index
        end
        return contents, tracknumber
      end

      def parse_node section, node, tracknumber
        if node.name.upcase=="DIV"
          contents = ''
          node.children.each do |n|
            next if n.blank?
            nodecontent, tracknumber = parse_node section, n, tracknumber
            contents+=nodecontent
          end
          return "<li>#{node.attribute('label')}</li><li><ul>#{contents}</ul></li>", tracknumber
        elsif ['SPAN','ITEM'].include? node.name.upcase
          tracknumber += 1
          start, stop = get_xml_media_fragment node, section
          label = "#{tracknumber}. #{node.attribute('label').value} (#{get_duration_from_fragment(start, stop)})"
          native_url = "#{id_section_media_object_path(@media_object, section.id)}?t=#{start},#{stop}"
          url = "#{share_link_for( section )}?t=#{start},#{stop}"
          segment_id = "#{section.id}-#{tracknumber}"
          data = {segment: section.id, is_video: section.file_format != 'Sound', native_url: native_url, fragmentbegin: start, fragmentend: stop}
          link = link_to label.html_safe, url, id: segment_id, data: data, class: 'playable structure wrap'
          return "<li class='stream-li'>#{link}</li>", tracknumber
        end
      end

      def get_xml_media_fragment node, section
        start = node.attribute('begin').present? ? node.attribute('begin').value : 0
        stop = node.attribute('end').present? ? node.attribute('end').value : section.duration.blank? ? 0 : milliseconds_to_formatted_time(section.duration.to_i)
        parse_media_fragment "#{start},#{stop}"
      end

      def get_duration node, section
        start,stop = get_xml_media_fragment node, section
        milliseconds_to_formatted_time((stop.to_i - start.to_i) * 1000, false)
      end

      def get_duration_from_fragment(start, stop)
        milliseconds_to_formatted_time((stop.to_i - start.to_i) * 1000, false)
      end

      # This method mirrors the one in the MediaObject model but makes use of the master files passed in which can be SpeedyAF Objects
      # This would be good to refactor in the future but speeds things up considerably for now
      def gather_all_comments(media_object, master_files)
        media_object.comment.sort + master_files.collect do |mf|
          mf.comment.reject(&:blank?).collect do |c|
            mf.display_title.present? ? "[#{mf.display_title}] #{c}" : c
          end.sort
        end.flatten.uniq
      end
end
