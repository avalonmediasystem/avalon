FactoryGirl.define do
  factory :minimal_record, class: MediaObject do
    title 'Minimal test record'
    creator 'RSpec'
    created_on Time.now
    abstract 'A bare bones test record with only required fields completed'
  end
  
  factory :single_entry, class: MediaObject do
    title 'Single contributor'
    creator 'RSpec'
    created_on Time.now
    abstract 'A record with only a single contributor and publisher'
    
    contributor 'RSpec helper'
    publisher 'Ruby on Rails'
    subject 'Programming'
  end
  
  factory :multiple_entries, class: MediaObject do
    title 'Multiple contributors'
    creator 'RSpec'
    created_on Time.now
    abstract 'A record with multiple contributors, publishers, and search terms'
    
    contributor ['Chris Colvard', 'Nathan Rogers', 'Phuong Dinh']
    publisher ['Mark Notess', 'Jon Dunn', 'Stu Baker']
    subject ['Programming', 'Ruby on Rails']
  end
end