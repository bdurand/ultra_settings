# frozen_string_literal: true

namespace :ultra_settings do
  desc <<~DOC
    Adds YARD documentation comments to configuration classes based on their field definitions.
  DOC
  task add_yard_docs: :environment do
    Rails.application.eager_load!

    UltraSettings.configurations.each_value do |config_class|
      documentation = UltraSettings::Tasks::Documentation.new(config_class)
      updated_sources = documentation.sources_with_yard_docs

      updated_sources.each do |path, content|
        next if File.read(path) == content

        File.write(path, content)
        puts "Updated configuration YARD docs in #{path}"
      end
    end
  end
end
