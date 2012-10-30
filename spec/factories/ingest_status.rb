FactoryGirl.define do
  factory :new_status, class: IngestStatus  do
    current_step HYDRANT_STEPS.first.step
    published false
  end
  factory :published, class: IngestStatus  do
    current_step HYDRANT_STEPS.last.step
    published true
  end
end
