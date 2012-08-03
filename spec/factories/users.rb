FactoryGirl.define do
  factory :cataloger, class: User  do
    username 'archivist1'
    #email 'archivist1@example.com'
    #password 'archivist1'
    #password_confirmation 'archivist1'
  end

  factory :content_provider, class: User  do
    username 'archivist2'
    #email 'archivist2@example.com'
    #password 'archivist1'
    #password_confirmation 'archivist1'
  end

  factory :student, class: User  do
    username 'ann.e.student'
    #email 'student@example.com'
    #password 'archivist1'
    #password_confirmation 'archivist1'
  end

  factory :public, class: User  do
    username 'average.joe'
    #email 'public.user@example.com'
    #password 'archivist1'
    #password_confirmation 'archivist1'
  end
end
