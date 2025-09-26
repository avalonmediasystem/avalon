json.extract! checkout, :id, :user_id, :media_object_id, :checkout_time, :return_time, :created_at, :updated_at
json.url checkout_url(checkout, format: :json)
