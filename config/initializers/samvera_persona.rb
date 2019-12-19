Samvera::Persona.setup do |config|
  config.soft_delete = false
end

Samvera::Persona::UsersController.class_eval do
  prepend_view_path 'views/samvera/persona/index.html.erb'
end
