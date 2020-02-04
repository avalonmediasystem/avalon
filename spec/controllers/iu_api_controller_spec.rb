require 'rails_helper'

RSpec.describe IuApiController, type: :controller do
  let(:media_object) { FactoryBot.create(:media_object) }
  let(:barcode) { '12345678901234' }

  describe "GET #media_object_structure" do
    let!(:master_file) { FactoryBot.create(:master_file, media_object: media_object, identifier: [barcode], title: 'Sample title') }
    let!(:master_file2) { FactoryBot.create(:master_file, media_object: media_object, identifier: [barcode], title: 'Sample title 2') }

    before do
      login_user media_object.collection.managers.first
    end

    it "returns a CSV" do
      get :media_object_structure, params: { id: media_object.id, format: 'csv' }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.size - 1).to eq(media_object.master_file_ids.size)
      expect(csv.first).to eq(['Label', 'MDPI Barcode', 'Masterfile ID', 'Order', 'Structure XML Filename'])
      expect(csv.second).to eq([master_file.title, barcode, master_file.id, '0', ''])
      expect(csv.third).to eq([master_file2.title, barcode, master_file2.id, '1', ''])
    end
  end

  describe "POST #media_object_structure_update" do
    let!(:master_file) { FactoryBot.create(:master_file, media_object: media_object, identifier: [barcode], title: 'Sample title') }

    let(:revised_csv) do
      get :media_object_structure, params: { id: media_object.id, format: 'csv' }
      csv = CSV.parse(response.body)
      csv.second[4] = structure_xml.original_filename
      csv.collect { |row| row.to_csv }.join
    end
    let(:structure_xml) { fixture_file_upload('/structure.xml', 'text/xml') }

    before do
      login_user media_object.collection.managers.first
    end

    context 'uploading structure files' do
      it "attaches structure to a section" do
        post :media_object_structure_update, params: { id: media_object.id, csv: revised_csv, structure: [structure_xml], format: 'csv' }
        media_object.reload
        expect(media_object.master_files.first.structuralMetadata).to be_present
      end
    end

    context 'reordering sections' do
      let!(:master_file2) { FactoryBot.create(:master_file, media_object: media_object, identifier: [barcode], title: 'Sample title 2') }
      let(:revised_csv) do
        get :media_object_structure, params: { id: media_object.id, format: 'csv' }
        csv = CSV.parse(response.body)
        csv.second[3] = 1
        csv.third[3] = 0
        csv.collect { |row| row.to_csv }.join
      end
  
      it 'reorders sections' do
        expect(media_object.ordered_master_files.to_a).to eq [master_file, master_file2]
        post :media_object_structure_update, params: { id: media_object.id, csv: revised_csv, format: 'csv' }
        media_object.reload
        expect(media_object.ordered_master_files.to_a).to eq [master_file2, master_file]
      end
    end
  end

  describe 'security' do
    describe 'ingest api' do
      it "all routes should return 403 when a bad token in present" do
        request.headers['Avalon-Api-Key'] = 'badtoken'
        expect(get :media_object_structure, params: { id: media_object.id, format: 'csv' }).to have_http_status(403)
        expect(post :media_object_structure_update, params: { id: media_object.id, csv: '', format: 'csv' }).to have_http_status(403)
      end
    end
    describe 'normal auth' do
      context 'with unauthenticated user' do
        it "all routes should redirect to sign in" do
          expect(get :media_object_structure, params: { id: media_object.id, format: 'csv' }).to redirect_to(/#{Regexp.quote(new_user_session_path)}\?url=.*/)
          expect(post :media_object_structure_update, params: { id: media_object.id, csv: '', format: 'csv' }).to redirect_to(/#{Regexp.quote(new_user_session_path)}\?url=.*/)
        end
      end
      context 'with end-user' do
        before do
          login_as :user
        end
        it "all routes should redirect to /" do
          expect(get :media_object_structure, params: { id: media_object.id, format: 'csv' }).to redirect_to(root_path)
          expect(post :media_object_structure_update, params: { id: media_object.id, csv: '', format: 'csv' }).to redirect_to(root_path)
        end
      end
    end
  end
end