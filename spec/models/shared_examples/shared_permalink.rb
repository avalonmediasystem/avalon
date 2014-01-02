shared_examples 'a permalinked object' do |object_klass|
  describe 'permalink' do
    
    let(:object){ FactoryGirl.build(object_klass.to_sym) }

    context 'unpublished' do
      it 'is empty when unpublished' do
        object.permalink.should be_empty
      end
    end

    context 'published' do
      before(:each){ object.publish!('Adam') } # saves the object
      it 'responds to permalink' do
        object.respond_to?(:permalink).should be_true
      end

      it 'sets the permalink on the object' do
        object.permalink.should_not be_nil
      end

      it 'sets the correct permalink' do
        object.permalink.should == 'http://www.example.com/perma-url'
      end

      it 'does not remove the permalink if the permalink service returns nil' do
        Permalink.on_generate{ nil }
        object.save( validate: false )
        object.permalink.should == 'http://www.example.com/perma-url'
      end

      it 'gracefully logs an error when the permalink service returns an exception' do
        Permalink.on_generate{ 1 / 0 }
        Rails.logger.should_receive(:error)
        object.save( validate: false )
      end
    end
  end
end