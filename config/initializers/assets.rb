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

# billboard.js ships its own stylesheet. Serving it from the installed package keeps
# it in lockstep with the JS version in package.json and page-scoped to /statistics
# (via stylesheet_link_tag "billboard"), rather than pulling a separate copy from a
# CDN or inflating the global bundle on every page.
Rails.application.config.assets.paths << Rails.root.join("node_modules/billboard.js/dist")
