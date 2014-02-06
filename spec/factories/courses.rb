# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :course do
    guid 'abcdef0123456789'
    label 'Existing Test Course'
  end
end
