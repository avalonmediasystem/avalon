# Be sure to restart your server when you modify this file.

Rails.application.config.assets.tap do |assets|
  # Version of your assets, change this if you want to expire all your assets.
  assets.version = '1.0'

  # Add additional assets to the asset load path
  # assets.paths << Emoji.images_path

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  # assets.precompile += %w( search.js )

  assets.precompile += %w( embed.css )

  # MediaElement 4 files
  assets.precompile += %w( mejs4_player.js mejs4_player.scss )
  assets.precompile += Dir[Rails.root + 'vendor/assets/stylesheets/mediaelement/mejs-controls.*']
  # MediaElement 2 files
  assets.precompile += %w( mejs2_player.js mejs2_player.scss )
end
