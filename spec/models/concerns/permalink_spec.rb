require 'spec_helper'

describe Permalink do

  describe '#permalink' do
    
    let(:master_file){ FactoryGirl.build(:master_file) }

    context 'permalink does not exist' do
      it 'returns nil' do
        master_file.permalink.should be_nil
      end

      it 'returns nil with query variables' do 
        master_file.permalink({a:'b'}).should be_nil
      end
    end

    context 'permalink exists' do
      
      let(:permalink_url){ "http://permalink.com/object/#{master_file.pid}" }
      
      before do 
        master_file.add_relationship(:has_permalink, permalink_url, true)
      end
      
      it 'returns a string' do
        master_file.permalink.should be_kind_of(String)
      end
      
      it 'appends query variables to the url' do
        query_var_hash = { urlappend: '/embed' }
        master_file.permalink(query_var_hash).should == "#{permalink_url}?#{query_var_hash.to_query}"
      end
    end

    context 'creating permalink' do
      let(:media_object) { FactoryGirl.build(:media_object) }
      
      it 'should get the absolute path to the object' do
        allow(media_object).to receive(:pid).and_return('avalon:item')
        allow(master_file).to receive(:pid).and_return('avalon:section')
        master_file.mediaobject = media_object
        expect(Permalink.url_for(media_object)).to eq('http://test.host/media_objects/avalon:item')
        expect(Permalink.url_for(master_file)).to eq('http://test.host/media_objects/avalon:item/section/avalon:section')
      end
      
      it 'permalink_for raises ArgumentError if not passed mediaobject or masterfile' do
        expect{Permalink.permalink_for(Object.new)}.to raise_error(ArgumentError)
      end      
    end

  end
end
