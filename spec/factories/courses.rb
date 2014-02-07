# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :course do
    context_id 'abcdef0123456789'
    label 'Existing Test Course'
  end
end
