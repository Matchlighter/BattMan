require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

def read_setting(key, fallback = nil)
  env_key = "BATTMAN_#{key.upcase.underscore}"
  return ENV[env_key] if ENV.key?(env_key)

  split = key.to_s.split(".")
  base = Rails.application.credentials.send(split[0].to_sym) || Rails.application.config_for(split[0])
  split.shift

  base&.dig(*split) || fallback
end

module Battman
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    config.mqtt = config_for(:mqtt)

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
