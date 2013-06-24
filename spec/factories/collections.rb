FactoryGirl.define do
  factory :collection do
    sequence(:name) {|n| "Collection #{n}" }
    sequence(:unit) {|n| "Unit #{n}"}
    managers {[FactoryGirl.create(:manager)] }
  end
end
