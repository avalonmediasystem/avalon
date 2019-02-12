json.extract! timeline, :id, :title, :user_id, :visibility, :description, :access_token, :tags, :source, :manifest, :created_at, :updated_at
json.url timeline_url(timeline, format: :json)
