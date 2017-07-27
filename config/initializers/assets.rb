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
Rails.application.config.assets.precompile += %w( mediaelement/mediaelement-and-player.js )
Rails.application.config.assets.precompile += %w( mediaelement/plugins/quality.js )
Rails.application.config.assets.precompile += %w( mediaelement/plugins/quality-i18n.js )
Rails.application.config.assets.precompile += %w( mediaelement/plugins/markers.js )

# MediaElement 2 files
Rails.application.config.assets.precompile += %w( jquery.js )
Rails.application.config.assets.precompile += %w( mediaelement_rails/index.js )
Rails.application.config.assets.precompile += %w( me-thumb-selector.js )
Rails.application.config.assets.precompile += %w( me-add-to-playlist.js )
Rails.application.config.assets.precompile += %w( me-track-scrubber.js )
Rails.application.config.assets.precompile += %w( mediaelement-qualityselector/mep-feature-qualities.js )
Rails.application.config.assets.precompile += %w( mediaelement-title/mep-feature-title.js )
Rails.application.config.assets.precompile += %w( mediaelement-hd-toggle/mep-feature-hdtoggle.js )
Rails.application.config.assets.precompile += %w( me-logo.js )
