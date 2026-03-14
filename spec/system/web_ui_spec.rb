# frozen_string_literal: true

require "spec_helper"

require "capybara/rspec"
require "capybara/cuprite"

require "rack"

begin
  require "super_settings"
  require "super_settings/storage/test_storage"
rescue LoadError
  # super_settings gem is not available; skip these tests.
end

# Build a Rack app for the system tests. This uses the real SuperSettings gem
# with in-memory storage so we can exercise the full edit flow.
RSpec.describe "Web UI", type: :system do
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    skip "super_settings gem is not available" unless defined?(::SuperSettings)
    SuperSettings::Setting.storage = SuperSettings::Storage::TestStorage

    # Register several configurations so the list has content to filter.
    UltraSettings.add(:my_service) unless UltraSettings.respond_to?(:my_service)
    UltraSettings.add(:explicit, "ExplicitConfiguration") unless UltraSettings.respond_to?(:explicit)
  end

  before do
    skip "super_settings gem is not available" unless defined?(::SuperSettings)

    @saved_editing = UltraSettings.instance_variable_get(:@super_settings_editing)
    @saved_runtime = UltraSettings.instance_variable_get(:@runtime_settings)
    @saved_secret = UltraSettings.instance_variable_get(:@fields_secret_by_default)

    # Enable super_settings editing for all tests by default
    UltraSettings.instance_variable_set(:@super_settings_editing, true)
    UltraSettings.runtime_settings = SuperSettings
    UltraSettings.fields_secret_by_default = false

    # Reset the test storage between examples
    SuperSettings::Storage::TestStorage.destroy_all
  end

  after do
    UltraSettings.instance_variable_set(:@super_settings_editing, @saved_editing)
    UltraSettings.instance_variable_set(:@runtime_settings, @saved_runtime)
    UltraSettings.fields_secret_by_default = @saved_secret if @saved_secret
  end

  let(:rack_app) { UltraSettings::RackApp.new }

  before do
    Capybara.app = rack_app
  end

  Capybara.server = :puma, {Silent: true}

  Capybara.register_driver :cuprite do |app|
    Capybara::Cuprite::Driver.new(app, window_size: [1400, 900], headless: true)
  end

  Capybara.default_driver = :cuprite
  Capybara.javascript_driver = :cuprite

  # Disable CSS transitions/animations to avoid flaky click timing in headless tests.
  def visit(*)
    super
    page.execute_script <<~JS
      if (!document.getElementById('ultra-settings-no-transitions')) {
        var s = document.createElement('style');
        s.id = 'ultra-settings-no-transitions';
        s.textContent = '*, *::before, *::after { transition-duration: 0s !important; animation-duration: 0s !important; }';
        document.head.appendChild(s);
      }
    JS
  end

  # Helper to select a configuration from the list view
  def select_config(name)
    find(".ultra-settings-config-list-item", text: name).click
  end

  describe "HTML direction attribute" do
    it "sets dir='ltr' on the html element for English locale" do
      visit "/"
      expect(page.find("html")["dir"]).to eq("ltr")
    end
  end

  describe "configuration list (default view)" do
    it "shows all configurations as clickable cards" do
      visit "/"

      within "#ultra-settings-config-list" do
        expect(page).to have_css(".ultra-settings-config-list-item", minimum: 2)
        expect(page).to have_text("MyServiceConfiguration")
        expect(page).to have_text("TestConfiguration")
      end

      # Config detail should not be visible
      expect(page).not_to have_css(".ultra-settings-config-detail.active")
    end

    it "selects a configuration when clicking a list item" do
      visit "/"

      select_config("MyServiceConfiguration")

      # List should be hidden, detail should be visible
      expect(page).to have_css(".ultra-settings-config-detail.active")
      expect(page).to have_css("#section-MyServiceConfiguration")

      # Search field should show config name
      search_input = find("#ultra-settings-search-input")
      expect(search_input.value).to eq("MyServiceConfiguration")
    end

    it "returns to the list view when clicking the clear button" do
      visit "/"

      select_config("MyServiceConfiguration")
      expect(page).to have_css(".ultra-settings-config-detail.active")

      find("#ultra-settings-search-clear").click

      # Should be back to list view
      expect(page).not_to have_css(".ultra-settings-config-detail.active")
      within "#ultra-settings-config-list" do
        expect(page).to have_css(".ultra-settings-config-list-item", minimum: 2)
      end

      # Search field should be empty
      search_input = find("#ultra-settings-search-input")
      expect(search_input.value).to eq("")
    end
  end

  describe "language menu" do
    it "switches locales from the topbar" do
      visit "/?lang=en"

      expect(page).to have_css("html[lang='en'][dir='ltr']")
      expect(page).to have_css(".ultra-settings-language-trigger-current", text: "English")

      find(".ultra-settings-language-trigger").click

      within ".ultra-settings-language-popup" do
        find(".ultra-settings-language-option", text: "Français").click
      end

      expect(page).to have_css("html[lang='fr'][dir='ltr']")
      expect(page).to have_css(".ultra-settings-language-trigger-current", text: "Français")
    end
  end

  describe "filtering configurations" do
    it "filters configurations in the list by typing in the search box" do
      visit "/"

      # All configurations should be visible initially
      within "#ultra-settings-config-list" do
        expect(page).to have_css(".ultra-settings-config-list-item", minimum: 2)
        expect(page).to have_text("MyServiceConfiguration")
        expect(page).to have_text("TestConfiguration")
      end

      # Type a filter term that matches only one configuration
      fill_in "ultra-settings-search-input", with: "MyService"

      within "#ultra-settings-config-list" do
        # MyServiceConfiguration should still be visible
        my_service_item = find(".ultra-settings-config-list-item", text: "MyServiceConfiguration")
        expect(my_service_item).not_to match_css(".hidden")

        # Other configurations should be hidden
        page.all(".ultra-settings-config-list-item").each do |item|
          next if item.text.include?("MyServiceConfiguration")
          expect(item[:class]).to include("hidden")
        end
      end

      # Clear the filter — all should reappear
      fill_in "ultra-settings-search-input", with: ""

      within "#ultra-settings-config-list" do
        page.all(".ultra-settings-config-list-item").each do |item|
          expect(item[:class]).not_to include("hidden")
        end
      end
    end
  end

  describe "showing configuration values" do
    it "displays field values inline on the page" do
      visit "/"
      select_config("MyServiceConfiguration")

      my_service_section = find("#section-MyServiceConfiguration")

      within my_service_section do
        # The port field should show its default value
        port_card = find(".ultra-settings-field-card[data-field-name='port']")
        within port_card do
          expect(page).to have_css(".ultra-settings-field-value", text: "80")
          expect(page).to have_css(".ultra-settings-type-label", text: "integer")
        end

        # The protocol field should show its default value
        protocol_card = find(".ultra-settings-field-card[data-field-name='protocol']")
        within protocol_card do
          expect(page).to have_css(".ultra-settings-field-value", text: "https")
        end

        # The timeout field should show the YAML value (shared section has 5.0)
        timeout_card = find(".ultra-settings-field-card[data-field-name='timeout']")
        within timeout_card do
          expect(page).to have_css(".ultra-settings-field-value", text: "5.0")
        end
      end
    end

    it "opens a detail panel when clicking a field value" do
      visit "/"
      select_config("MyServiceConfiguration")

      my_service_section = find("#section-MyServiceConfiguration")

      within my_service_section do
        port_value = find(".ultra-settings-field-card[data-field-name='port'] .ultra-settings-field-value")
        port_value.click
      end

      # The detail panel should slide open
      expect(page).to have_css("#ultra-settings-detail-panel.open", wait: 5)
      detail_panel = find("#ultra-settings-detail-panel")
      expect(detail_panel).to have_text("port")
      expect(detail_panel).to have_text("80")
      expect(detail_panel).to have_text("INTEGER")
    end

    it "closes the detail panel via the close button" do
      visit "/"
      select_config("MyServiceConfiguration")

      my_service_section = find("#section-MyServiceConfiguration")
      within my_service_section do
        find(".ultra-settings-field-card[data-field-name='port'] .ultra-settings-field-value").click
      end

      expect(page).to have_css("#ultra-settings-detail-panel.open", wait: 5)

      find("#ultra-settings-dp-close").click

      expect(page).not_to have_css("#ultra-settings-detail-panel.open")
    end

    it "shows field descriptions" do
      visit "/"
      select_config("MyServiceConfiguration")

      my_service_section = find("#section-MyServiceConfiguration")
      within my_service_section do
        timeout_card = find(".ultra-settings-field-card[data-field-name='timeout']")
        within timeout_card do
          expect(page).to have_text("Network timeout in seconds")
        end
      end
    end

    it "shows data source information for each field" do
      visit "/"
      select_config("MyServiceConfiguration")

      my_service_section = find("#section-MyServiceConfiguration")
      within my_service_section do
        port_card = find(".ultra-settings-field-card[data-field-name='port']")
        within port_card do
          # Port has env, settings, yaml, and default sources
          expect(page).to have_css(".ultra-settings-source-row", minimum: 2)
          # Default should be marked active since no other source is set
          expect(page).to have_css(".ultra-settings-sb-active", text: /Active/)
        end
      end
    end
  end

  describe "editing a SuperSetting" do
    it "opens the edit panel and saves a new runtime setting" do
      visit "/"
      select_config("MyServiceConfiguration")

      my_service_section = find("#section-MyServiceConfiguration")

      within my_service_section do
        # Find the timeout field's runtime setting edit button
        timeout_card = find(".ultra-settings-field-card[data-field-name='timeout']")
        within timeout_card do
          find(".ultra-settings-ss-edit-btn").click
        end
      end

      # The SuperSettings edit panel should open
      expect(page).to have_css("#ultra-settings-ss-panel.open", wait: 5)
      ss_panel = find("#ultra-settings-ss-panel")

      # Wait for the form to appear (loading state completes)
      within ss_panel do
        expect(page).to have_css("#ultra-settings-ss-form", visible: true, wait: 5)

        # The key should be pre-populated
        expect(find("#ultra-settings-ss-key").value).to eq("my_service.timeout")

        # Fill in a new value (timeout is a float, so use the float number input)
        fill_in "ultra-settings-ss-float-value", with: "5.0"

        # Fill in a description
        fill_in "ultra-settings-ss-description", with: "Updated timeout"

        # Click save
        click_button "Save"
      end

      # After saving, the page reloads. Wait for the page to settle.
      expect(page).to have_css(".ultra-settings", wait: 10)

      # Verify the setting was saved in SuperSettings
      setting = SuperSettings::RestAPI.show("my_service.timeout")
      expect(setting).not_to be_nil
      expect(setting[:value].to_s).to eq("5.0")
    end

    it "can cancel editing without saving" do
      visit "/"
      select_config("MyServiceConfiguration")

      my_service_section = find("#section-MyServiceConfiguration")
      within my_service_section do
        timeout_card = find(".ultra-settings-field-card[data-field-name='timeout']")
        within timeout_card do
          find(".ultra-settings-ss-edit-btn").click
        end
      end

      expect(page).to have_css("#ultra-settings-ss-panel.open", wait: 5)

      within "#ultra-settings-ss-panel" do
        expect(page).to have_css("#ultra-settings-ss-form", visible: true, wait: 5)
        click_button "Cancel"
      end

      expect(page).not_to have_css("#ultra-settings-ss-panel.open")

      # Nothing should have been saved
      setting = SuperSettings::RestAPI.show("my_service.timeout")
      expect(setting).to be_nil
    end

    it "does not show edit buttons when super_settings editing is disabled" do
      UltraSettings.instance_variable_set(:@super_settings_editing, false)

      visit "/"
      select_config("MyServiceConfiguration")

      expect(page).not_to have_css(".ultra-settings-ss-edit-btn")
      expect(page).not_to have_css("#ultra-settings-ss-panel")
    end

    it "pre-populates the form when editing an existing setting" do
      # Create a setting in SuperSettings first
      SuperSettings::RestAPI.update([
        {"key" => "my_service.host", "value" => "example.com", "value_type" => "string", "description" => "The host"}
      ])

      visit "/"
      select_config("MyServiceConfiguration")

      my_service_section = find("#section-MyServiceConfiguration")
      within my_service_section do
        host_card = find(".ultra-settings-field-card[data-field-name='host']")
        within host_card do
          find(".ultra-settings-ss-edit-btn").click
        end
      end

      ss_panel = find("#ultra-settings-ss-panel")
      within ss_panel do
        expect(page).to have_css("#ultra-settings-ss-form", visible: true, wait: 5)

        # The form should be pre-populated with existing values
        expect(find("#ultra-settings-ss-key").value).to eq("my_service.host")
        expect(find("#ultra-settings-ss-value").value).to eq("example.com")
        expect(find("#ultra-settings-ss-description").value).to eq("The host")
      end
    end
  end

  describe "hash-based navigation" do
    it "auto-selects a configuration from the URL hash" do
      visit "/#MyServiceConfiguration"

      # Should show MyServiceConfiguration detail view
      expect(page).to have_css(".ultra-settings-config-detail.active")
      expect(page).to have_css("#section-MyServiceConfiguration[style='']", wait: 5)
    end
  end
end
