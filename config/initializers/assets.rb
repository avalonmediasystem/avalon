# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile += %w( embed.css )

# MediaElement 4 files
Rails.application.config.assets.precompile += %w( mejs4_player.js )
Rails.application.config.assets.precompile += %w( mejs4_player.scss )

# MediaElement 2 files
Rails.application.config.assets.precompile += %w( mejs2_player.js )
Rails.application.config.assets.precompile += %w( mejs2_player.scss )
