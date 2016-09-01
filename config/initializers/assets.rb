# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile += %w( mediaelement_rails/mediaelement-and-player.js )
Rails.application.config.assets.precompile += %w( mediaelement-qualityselector/mep-feature-qualities.js )
Rails.application.config.assets.precompile += %w( me-thumb-selector.js )
Rails.application.config.assets.precompile += %w( mediaelement-skin-avalon/mep-feature-responsive.js )
Rails.application.config.assets.precompile += %w( me-add-to-playlist.js )
Rails.application.config.assets.precompile += %w( mediaelement-qualityselector/mep-feature-qualities.css )
Rails.application.config.assets.precompile += %w( me-thumb-selector.css )
Rails.application.config.assets.precompile += %w( mediaelement-skin-avalon/mejs-skin-avalon.css )
Rails.application.config.assets.precompile += %w( me-add-to-playlist.css )
