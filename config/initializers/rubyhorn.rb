require 'rubyhorn'
config = {:uri=>"http://localhost:8080/",
          :user=>'matterhorn_system_account',
          :password=>'CHANGE_ME' }
Rubyhorn.connect(config)
