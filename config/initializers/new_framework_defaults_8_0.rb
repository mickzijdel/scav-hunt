# Be sure to restart your server when you modify this file.
#
# This file eases your Rails 8.0 framework defaults upgrade.
#
# Uncomment each configuration one by one to switch to the new default.
# Once your application is ready to run with all new defaults, you can remove
# this file and set the `config.load_defaults` to `8.0`.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html

###
# Specifies whether `to_time` methods preserve the UTC offset of their receivers or preserves the timezone.
# If set to `:zone`, `to_time` methods will use the timezone of their receivers.
# If set to `:offset`, `to_time` methods will use the UTC offset.
# If `false`, `to_time` methods will convert to the local system UTC offset instead.
#
# NOT APPLICABLE on Rails 8.1: `config.active_support.to_time_preserves_timezone` is a
# deprecated no-op shim at 8.1 (removed in 8.2) because 8.1 made `#to_time` always preserve
# the receiver's timezone. Rails 8.1's own `load_defaults "8.0"` branch omits it for the same
# reason. Uncommenting this only emits a deprecation warning; it changes nothing.
#++
# Rails.application.config.active_support.to_time_preserves_timezone = :zone

###
# When both `If-Modified-Since` and `If-None-Match` are provided by the client
# only consider `If-None-Match` as specified by RFC 7232 Section 6.
# If set to `false` both conditions need to be satisfied.
#
# CANNOT BE SET FROM HERE. Action Pack copies this config into
# `ActionDispatch::Http::Cache::Request.strict_freshness` in its `action_dispatch.configure`
# railtie initializer (position 26), which runs long before `load_config_initializers`
# (position 113) loads this file. Assigning it here is a silent no-op — verified by reading
# back `ActionDispatch::Http::Cache::Request.strict_freshness`, which stayed `false`.
#
# It is therefore set in `config/application.rb` instead, which is evaluated before any
# railtie initializer. That is also where `load_defaults 8.0` would set it.
#++
# Rails.application.config.action_dispatch.strict_freshness = true  # <- see above; set in application.rb

###
# Set `Regexp.timeout` to `1`s by default to improve security over Regexp Denial-of-Service attacks.
#++
Regexp.timeout = 1
