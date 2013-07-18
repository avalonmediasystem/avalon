FactoryGirl.define do
  factory :derivative do
    after(:create) do |d|
      d.masterfile = FactoryGirl.create(:master_file)
      d.save
    end
  end
end
