# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed 
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

FactoryGirl.define do
  factory :cataloger, class: User  do
    username 'archivist1@example.com'
    email 'archivist1@example.com'
    #password 'archivist1'
    #password_confirmation 'archivist1'
  end

  factory :policy_editor, class: User  do
    username 'archivist1@example.com'
    email 'archivist1@example.com'
    #password 'archivist1'
    #password_confirmation 'archivist1'
  end

  factory :content_provider, class: User  do
    username 'archivist2'
    email 'archivist2@example.com'
    #password 'archivist1'
    #password_confirmation 'archivist1'
  end

  factory :student, class: User  do
    username 'ann.e.student'
    email 'student@example.com'
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
