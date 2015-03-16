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

end
