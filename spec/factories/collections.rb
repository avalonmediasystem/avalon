FactoryGirl.define do
  factory :collection do
    sequence(:name) {|n| "Collection #{n}" }
    unit {"University Archives"}
    description {Faker::Lorem.sentence}
    managers {[FactoryGirl.create(:manager)]}
    editors {[FactoryGirl.create(:editor)]}
    depositors {[FactoryGirl.create(:depositor)]}
  end
end
