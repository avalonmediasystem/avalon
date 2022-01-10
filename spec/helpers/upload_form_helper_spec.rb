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

require 'rails_helper'

describe UploadFormHelper, type: :helper do
  describe '.direct_upload?' do
    before do
      allow(Settings).to receive(:encoding).and_return(double())
      allow(Settings.encoding).to receive(:engine_adapter).and_return(transcoder)
    end

    context 'with elastic transcoder' do
      let(:transcoder) { :elastic_transcoder }
      it 'returns true if using Elastic Transcoder' do
        expect(helper.direct_upload?).to be true
      end
    end

    context 'with Minio' do
      let(:transcoder) { :any }
      before do
        Settings.minio = double("minio", endpoint: "http://minio:9000", public_host: "http://domain:9000")
      end

      it 'returns true if using Minio' do
        expect(helper.direct_upload?).to be true
      end

      after do
        Settings.minio = nil
      end
    end

    context 'with another transcoder' do
      let(:transcoder) { :matterhorn }
      it 'returns true if using Elastic Transcoder' do
        expect(helper.direct_upload?).to be false
      end
    end
  end

  describe '.upload_form_classes' do
    context 'with direct upload' do
      before { allow(helper).to receive(:direct_upload?).and_return(true) }
      it 'includes the direct_upload class' do
        expect(helper.upload_form_classes).to include("directupload")
      end
    end
    
    context 'without direct upload' do
      before { allow(helper).to receive(:direct_upload?).and_return(false) }
      it 'does not include the direct_upload class' do
        expect(helper.upload_form_classes).not_to include("directupload")
      end
    end
  end

  describe '.upload_form_data' do
    context 'with direct upload' do
      before do
        allow(helper).to receive(:direct_upload?).and_return(true)
        allow(Settings).to receive(:encoding).and_return(double())
        allow(Settings.encoding).to receive(:masterfile_bucket).and_return("bucket-id")
      end

      it 'includes the direct_upload class' do
        expect(helper.upload_form_data).to include('form-data', 'url', 'host')
      end
    end
   
    context 'without direct upload' do
      before { allow(helper).to receive(:direct_upload?).and_return(false) }
      it 'does not include the direct_upload class' do
        expect(helper.upload_form_data).to be_empty
      end
    end
  end
end
