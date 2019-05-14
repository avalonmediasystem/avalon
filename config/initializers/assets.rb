# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

Rails.application.config.assets.precompile += %w( embed.css )

# MediaElement 4 files
Rails.application.config.assets.precompile += %w( mejs4_player.js mejs4_player.scss select2.min.js select2.min.css )
Rails.application.config.assets.precompile += Dir[Rails.root + 'vendor/assets/stylesheets/mediaelement/mejs-controls.*']

