require "rails_helper"

RSpec.describe BatchRegistriesMailer, type: :mailer do
  describe 'batch_ingest_validation_error' do
    let(:manager) { FactoryGirl.create(:manager, username: 'frances.dickens@reichel.com', email: 'frances.dickens@reichel.com') }
    let(:collection) { FactoryGirl.build(:collection, managers: [manager.user_key]) }
    let(:manifest_file) { File.new('spec/fixtures/dropbox/example_batch_ingest/batch_manifest.xlsx') }
    let(:package) { Avalon::Batch::Package.new(manifest_file, collection) }
    let(:errors) {['Michigan','Indiana','Illinios']}
    let(:notification_email_address) { Avalon::Configuration.lookup('email.notification') }

    it "sends to the user when package has a registered user's email" do
       email = BatchRegistriesMailer.batch_ingest_validation_error(package, errors)
       expect(email.to).to include(manager.email)
       expect(email.subject).to have_content(collection.id)
       expect(email).to have_body_text(package.title)
       errors.each do |error|
         expect(email).to have_body_text(error)
       end  
    end

    it "sends to notification email address if manifest's email does not belong to a registered user" do
       allow(package).to receive(:user).and_return(nil)
       email = BatchRegistriesMailer.batch_ingest_validation_error(package, errors)
       expect(email.to).to include(notification_email_address)
    end
  end
end
