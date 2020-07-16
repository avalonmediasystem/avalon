# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

require 'rails_helper'

describe SecurityHelper, type: :helper do
  let(:stream_info) {
    {:id=>"bk1289888", :label=>nil, :is_video=>true, :poster_image=>nil, :embed_code=>"", :stream_hls=>[{:quality=>nil, :mimetype=>nil, :format=>"other", :url=>"http://localhost:3000/6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4.m3u8"}], :captions_path=>nil, :captions_format=>nil, :duration=>200.0, :embed_title=>"Fugit veniam numquam harum et adipisci est est. - video.mp4"}
  }
  let(:secure_url) { "http://example.com/secure/id" }

  before do
    allow(SecurityHandler).to receive(:secure_url).and_return(secure_url)
  end

  context 'when AWS streaming server' do
    let(:secure_cookies) { {"CloudFront-12345" => {
	  value: 'abcdefg',
	  path: "/#{stream_info[:id]}",
	  domain: "example.com",
	  expires: Settings.streaming.stream_token_ttl.minutes.from_now
	}}}

    before do
      allow(SecurityHandler).to receive(:secure_cookies).with(target: stream_info[:id], request_host: controller.request.server_name).and_return(secure_cookies)
    end

    describe '#add_stream_cookies' do
      it 'adds security tokens to cookies' do
	expect { helper.add_stream_cookies(stream_info) }.to change { controller.cookies.sum {|k,v| 1} }.by(1)
	expect(controller.cookies[secure_cookies.first[0]]).to eq secure_cookies.first[1][:value]
      end
    end

    describe '#secure_streams' do
      it 'sets secure cookies' do
	expect { helper.secure_streams(stream_info) }.to change { controller.cookies.sum {|k,v| 1} }.by(1)
	expect(controller.cookies[secure_cookies.first[0]]).to eq secure_cookies.first[1][:value]
      end

       it 'rewrites urls in the stream_info' do
         expect { helper.secure_streams(stream_info) }.to change { stream_info.slice(:stream_flash, :stream_hls).values.flatten.collect {|v| v[:url]} }
         [:stream_flash, :stream_hls].each do |protocol|
           stream_info[protocol].each do |quality|
             expect(quality[:url]).to eq secure_url
           end
         end
       end
    end
  end

  context 'when using non-AWS streaming server' do
    describe '#add_stream_cookies' do
      it 'adds security tokens to cookies' do
        expect { helper.add_stream_cookies(stream_info) }.not_to change { controller.cookies.sum {|k,v| 1} }
      end
    end

    describe '#secure_streams' do
      it 'sets secure cookies' do
        expect { helper.secure_streams(stream_info) }.not_to change { controller.cookies.sum {|k,v| 1} }
      end

      it 'rewrites urls in the stream_info' do
        expect { helper.secure_streams(stream_info) }.to change { stream_info.slice(:stream_flash, :stream_hls).values.flatten.collect {|v| v[:url]} }
        [:stream_flash, :stream_hls].each do |protocol|
          stream_info[protocol].each do |quality|
            expect(quality[:url]).to eq secure_url
          end
        end
      end
    end
  end
end
