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

RSpec.describe IndexHeaderMediaObjectComponent, type: :component do
  let(:component) { described_class.new(presenter: presenter, **attr) }

  let(:presented_document) { SolrDocument.new(id: 'abcd1234', title_tesi: 'Title', duration_ssi: '361000', has_model_ssim: ['MediaObject']) }

  let(:presenter) { vc_test_controller.view_context.document_presenter(presented_document) }

  before do
    with_controller_class(CatalogController) do
      allow(vc_test_controller).to receive_messages(current_user: nil)
      render_inline described_class.new(presenter: presenter)
    end
  end

  it 'renders title with duration' do
    expect(page).to have_content 'Title (06:01)'
  end

  context 'without title' do
    let(:presented_document) { SolrDocument.new(id: 'abcd1234', duration_ssi: '361100', has_model_ssim: ['MediaObject']) }

    it 'renders id with duration' do
      expect(page).to have_content 'abcd1234 (06:01)'
    end
  end

  context 'without duration' do
    let(:presented_document) { SolrDocument.new(id: 'abcd1234', title_tesi: 'Title', has_model_ssim: ['MediaObject']) }

    it 'renders title without duration' do
      expect(page).to have_content 'Title'
    end
  end
end
