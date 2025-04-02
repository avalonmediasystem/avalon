# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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
  let(:media_object) { FactoryBot.create(:media_object) }
  let(:user) { FactoryBot.create(:user) }

  before do
    allow(SecurityHandler).to receive(:secure_url).and_return(secure_url)
    allow(helper).to receive(:current_user).and_return(user)
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
      context 'controlled digital lending is disabled' do
        before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(false) }
        it 'sets secure cookies' do
        	expect { helper.secure_streams(stream_info, media_object.id) }.to change { controller.cookies.sum {|k,v| 1} }.by(1)
        	expect(controller.cookies[secure_cookies.first[0]]).to eq secure_cookies.first[1][:value]
        end

        it 'rewrites urls in the stream_info' do
          expect { helper.secure_streams(stream_info, media_object.id) }.to change { stream_info.slice(:stream_flash, :stream_hls).values.flatten.collect {|v| v[:url]} }
          [:stream_hls].each do |protocol|
            stream_info[protocol].each do |quality|
              expect(quality[:url]).to eq secure_url
            end
          end
        end
      end
      context 'controlled digital lending is enabled' do
        before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(true) }
        before { allow(Settings.controlled_digital_lending).to receive(:collections_enabled).and_return(true) }
        context 'the user has the item checked out' do
          before { FactoryBot.create(:checkout, media_object_id: media_object.id, user_id: user.id)}
          it 'sets secure cookies' do
          	expect { helper.secure_streams(stream_info, media_object.id) }.to change { controller.cookies.sum {|k,v| 1} }.by(1)
          	expect(controller.cookies[secure_cookies.first[0]]).to eq secure_cookies.first[1][:value]
          end

          it 'rewrites urls in the stream_info' do
            expect { helper.secure_streams(stream_info, media_object.id) }.to change { stream_info.slice(:stream_flash, :stream_hls).values.flatten.collect {|v| v[:url]} }
            [:stream_hls].each do |protocol|
              stream_info[protocol].each do |quality|
                expect(quality[:url]).to eq secure_url
              end
            end
          end
        end
        context 'the user does not have the item checked out' do
          it 'does not set secure cookies' do
          	expect { helper.secure_streams(stream_info, media_object.id) }.not_to change { controller.cookies.sum {|k,v| 1} }
          	expect(controller.cookies[secure_cookies.first[0]]).not_to eq secure_cookies.first[1][:value]
          end

          it 'does not rewrite urls in the stream_info' do
            expect { helper.secure_streams(stream_info, media_object.id) }.not_to change { stream_info.slice(:stream_flash, :stream_hls).values.flatten.collect {|v| v[:url]} }
            [:stream_hls].each do |protocol|
              stream_info[protocol].each do |quality|
                expect(quality[:url]).not_to eq secure_url
              end
            end
          end
        end
      end
    end
  end

  context 'when using non-AWS streaming server' do
    describe '#add_stream_cookies' do
      it 'does not add security tokens to cookies' do
        expect { helper.add_stream_cookies(stream_info) }.not_to change { controller.cookies.sum {|k,v| 1} }
      end
    end

    describe '#secure_streams' do
      context 'controlled digital lending is disabled' do
        before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(false) }
        it 'sets secure cookies' do
          expect { helper.secure_streams(stream_info, media_object.id) }.not_to change { controller.cookies.sum {|k,v| 1} }
        end

        it 'rewrites urls in the stream_info' do
          expect { helper.secure_streams(stream_info, media_object.id) }.to change { stream_info.slice(:stream_flash, :stream_hls).values.flatten.collect {|v| v[:url]} }
          [:stream_hls].each do |protocol|
            stream_info[protocol].each do |quality|
              expect(quality[:url]).to eq secure_url
            end
          end
        end
      end
      context 'controlled digital lending is enabled' do
        before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(true) }
        before { allow(Settings.controlled_digital_lending).to receive(:collections_enabled).and_return(true) }
        context 'the user has the item checked out' do
          before { FactoryBot.create(:checkout, media_object_id: media_object.id, user_id: user.id)}
          it 'sets secure cookies' do
            expect { helper.secure_streams(stream_info, media_object.id) }.not_to change { controller.cookies.sum {|k,v| 1} }
          end

          it 'rewrites urls in the stream_info' do
            expect { helper.secure_streams(stream_info, media_object.id) }.to change { stream_info.slice(:stream_flash, :stream_hls).values.flatten.collect {|v| v[:url]} }
            [:stream_hls].each do |protocol|
              stream_info[protocol].each do |quality|
                expect(quality[:url]).to eq secure_url
              end
            end
          end
        end
        context 'the user does not have the item checked out' do
          it 'sets secure cookies' do
            expect { helper.secure_streams(stream_info, media_object.id) }.not_to change { controller.cookies.sum {|k,v| 1} }
          end

          it 'does not rewrite urls in the stream_info' do
            expect { helper.secure_streams(stream_info, media_object.id) }.not_to change { stream_info.slice(:stream_flash, :stream_hls).values.flatten.collect {|v| v[:url]} }
            [:stream_hls].each do |protocol|
              stream_info[protocol].each do |quality|
                expect(quality[:url]).not_to eq secure_url
              end
            end
          end
        end
      end
    end

    describe '#secure_stream_infos' do
      let(:master_file) { FactoryBot.create(:master_file, :with_derivative, media_object: media_object) }
      let(:token) { 'dcba-4321' }
      let(:secure_url_with_token) { secure_url + "?token=#{token}" }

      before do
        allow(SecurityHandler).to receive(:secure_url).with(String, token: token).and_return(secure_url_with_token)
      end

      context 'controlled digital lending is disabled' do
        before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(false) }

        it 'rewrites urls in the stream_infos' do
          stream_info_hash = helper.secure_stream_infos([master_file], [media_object])
          stream_info = stream_info_hash[master_file.id]
          [:stream_hls].each do |protocol|
            stream_info[protocol].each do |quality|
              expect(quality[:url]).to eq secure_url
            end
          end
        end
      end

      context 'controlled digital lending is enabled' do
        before { allow(Settings.controlled_digital_lending).to receive(:enable).and_return(true) }
        before { allow(Settings.controlled_digital_lending).to receive(:collections_enabled).and_return(true) }

        context 'the user has the item checked out' do
          before { FactoryBot.create(:checkout, media_object_id: media_object.id, user_id: user.id)}

          it 'rewrites urls in the stream_infos' do
            stream_info_hash = helper.secure_stream_infos([master_file], [media_object])
            stream_info = stream_info_hash[master_file.id]
            [:stream_hls].each do |protocol|
              stream_info[protocol].each do |quality|
                expect(quality[:url]).to eq secure_url
              end
            end
          end
        end

        context 'the user does not have the item checked out' do
          it 'does not rewrite urls in the stream_info' do
            stream_info_hash = helper.secure_stream_infos([master_file], [media_object])
            stream_info = stream_info_hash[master_file.id]
            [:stream_hls].each do |protocol|
              stream_info[protocol].each do |quality|
                expect(quality[:url]).not_to eq secure_url
              end
            end
          end
        end
      end
    end
  end
end
