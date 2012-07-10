FactoryGirl.define do
  factory :user do
		email 'testuser@example.com'
		password '123456'
        
    # Child of :user factory, since it's in the `factory :user` block
    factory :archivist do
      email 'archivist1@example.com'
    end
  end
end

