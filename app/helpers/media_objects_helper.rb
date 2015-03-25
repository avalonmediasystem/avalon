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
        path = URI::Parser.new.escape(collection.dropbox_directory_name, %r{[/\\%& #]})
        url = File.join(Avalon::Configuration.lookup('dropbox.upload_uri'), path)
        ic.iconv(url)
     end
     
     def combined_display_date mediaobject
       (issued,created) = case mediaobject
       when MediaObject
         [mediaobject.date_issued, mediaobject.date_created]
       when Hash
         [mediaobject[:document]['date_ssi'], mediaobject[:document]['date_created_ssi']]
       end
       result = issued
       result += " (Creation date: #{created})" if created.present?
       result
     end

     def display_language mediaobject
       mediaobject.language.collect{|l|l[:text]}
     end

     def display_related_item mediaobject
       mediaobject.related_item_url.collect{ |r| link_to( r[:label], r[:url]) }
     end

     def current_quality stream_info
       available_qualities = Array(stream_info[:stream_flash]).collect {|s| s[:quality]}
       available_qualities += Array(stream_info[:stream_hls]).collect {|s| s[:quality]}
       available_qualities.uniq!
       quality ||= session[:quality] if session['quality'].present? && available_qualities.include?(session[:quality])
       quality ||= Avalon::Configuration.lookup('streaming.default_quality') if available_qualities.include?(Avalon::Configuration.lookup('streaming.default_quality'))
       quality ||= available_qualities.first
       quality
     end

     def parse_hour_min_sec s
       return nil if s.nil?
       smh = s.split(':').reverse
       (Float(smh[0]) rescue 0) + 60*(Float(smh[1]) rescue 0) + 3600*(Float(smh[2]) rescue 0)
     end

     def parse_media_fragment_param
       return 0,nil if !params['t'].present?
       f_start,f_end = params['t'].split(',')
       return parse_hour_min_sec(f_start) , parse_hour_min_sec(f_end)
     end

     def is_current_section? section
        section.pid == @currentStream.pid
     end

     def structure_html section, index
       sm = section.get_structural_metadata
       return "" if sm.xpath('//Item').empty?
       sectionnode = sm.xpath('//Item')
       sectionlabel = sectionnode.attribute('label').value
       current = is_current_section? section

       s = <<EOF
    <div class="panel-heading" role="tab" id="heading#{index}">
      <a data-toggle="collapse" href="#section#{index}" aria-expanded="#{current ? 'true' : 'false' }" aria-controls="collapse#{index}">
        <h4 class="panel-title">
          <span class="fa fa-minus-square #{current ? '' : 'hidden'}"></span>
          <span class="fa fa-plus-square #{current ? 'hidden' : ''}"></span>
          <span>#{sectionlabel}</span>
        </h4>
      </a>
    </div>
    <div id="section#{index}" class="panel-collapse collapse #{current ? 'in' : ''}" role="tabpanel" aria-labelledby="heading#{index}">
      <div class="panel-body">
        <ul>
EOF
       tracknumber = 0
       sectionnode.children.each do |node| 
         st, tracknumber = parse_node section, node, tracknumber
         s+=st
       end
       s += <<EOF
        </ul>
      </div>
    </div>
EOF
     end

     def parse_node section, node, tracknumber
       if node.name.upcase=="DIV"
         contents = ''
         node.children.each { |n| nodecontent, tracknumber = parse_node section, n, tracknumber; contents+=nodecontent }
         return "<li>#{node.attribute('label')}</li><li><ul>#{contents}</ul></li>", tracknumber
       elsif node.name.upcase=="SPAN"
         tracknumber += 1
         label = "#{tracknumber}. #{node.attribute('label').value}"
         url = "#{share_link_for( section )}?t=#{node.attribute('begin').value},#{node.attribute('end').value}"
         data =  {segment: section.pid, is_video: section.is_video?, share_link: url}
         myclass = section.pid == @currentStream.pid ? 'current-stream' : nil
         link = link_to label, url, data: data, class: myclass
         return "<li class='stream-li'>#{link}</li>", tracknumber
       end
     end

end
