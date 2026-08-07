# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
Rails.application.config.assets.paths << Rails.root.join("node_modules/bootstrap-icons/font")

# Almendra SC, self-hosted from the @fontsource package. Adding the package's
# `files` directory makes each font file resolvable by its bare filename, so the
# @font-face in application.bootstrap.scss can reference it and Propshaft can
# fingerprint it — the same arrangement as bootstrap-icons above.
Rails.application.config.assets.paths << Rails.root.join("node_modules/@fontsource/almendra-sc/files")
