FactoryGirl.define do
  factory :collection do
    sequence(:name) {|n| "Collection #{n}" }
    unit {"University Archives"}
    description {Faker::Lorem.sentence}
    managers {[FactoryGirl.create(:manager).username]}
    editors {[FactoryGirl.create(:editor).username]}
    depositors {[FactoryGirl.create(:depositor).username]}
  end
end
