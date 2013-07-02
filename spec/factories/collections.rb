FactoryGirl.define do
  factory :collection do
    sequence(:name) {|n| "Collection #{n}" }
    unit {"University Archives"}
    description {Faker::Lorem.sentence}
    managers {[FactoryGirl.create(:manager).username]}
    editors {[FactoryGirl.create(:user).username]}
    depositors {[FactoryGirl.create(:user).username]}
  end
end
