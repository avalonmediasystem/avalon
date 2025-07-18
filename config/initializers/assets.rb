# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

# MediaElement 4 files
# autocomplete and pop_help need to be explicitly precompiled for inclusion in update_access_control.html.erb
# Possibly this is only necessary in dev and test envs.
Rails.application.config.assets.precompile += %w(select2.min.js select2.min.css autocomplete.js pop_help.js)
