FactoryGirl.define do
  factory :master_file do
    status_code {Faker::Lorem.word}
    file_location {'/path/to/video.mp4'}
    percent_complete {"#{rand(100)}"}
    after(:create) do |mf|
      mf.mediaobject = FactoryGirl.create(:media_object)
      mf.save
    end
  end
end
