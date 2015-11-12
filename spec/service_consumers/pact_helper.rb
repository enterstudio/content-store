ENV["RAILS_ENV"]="test"
require "webmock"
require "pact/provider/rspec"
require "rails_helper"

WebMock.disable!

Pact.configure do | config |
  config.reports_dir = "spec/reports/pacts"
  config.include WebMock::API
  config.include WebMock::Matchers
end

Pact.service_provider "Content Store" do
  honours_pact_with "Publishing API" do
    if ENV['USE_LOCAL_PACT']
      pact_uri ENV.fetch('PUBLISHING_API_PACT_PATH', '../publishing-api/spec/pacts/publishing_api-content_store.json')
    else
      base_url = "https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/#{URI.escape(name)}/consumer/#{URI.escape(consumer_name)}"
      version_part = ENV['PUBLISHING_API_PACT_VERSION'] ? "versions/#{ENV['PUBLISHING_API_PACT_VERSION']}" : 'latest'

      pact_uri "#{base_url}/#{version_part}"
    end
  end

end

Pact.provider_states_for "Publishing API" do
  set_up do
    WebMock.enable!
    WebMock.reset!
  end

  tear_down do
    WebMock.disable!
  end

  provider_state "a content item exists with base_path /vat-rates and transmitted_at 1000000000000000000" do
    set_up do
      DatabaseCleaner.clean_with :truncation
      stub_request(:any, Regexp.new(Plek.find("router-api")))

      FactoryGirl.create(
        :content_item,
        base_path: "/vat-rates",
        transmitted_at: "1000000000000000000",
      )
    end
  end

  provider_state "a content item exists with base_path /vat-rates and transmitted_at 3000000000000000000" do
    set_up do
      DatabaseCleaner.clean_with :truncation
      stub_request(:any, Regexp.new(Plek.find("router-api")))

      FactoryGirl.create(
        :content_item,
        base_path: "/vat-rates",
        transmitted_at: "3000000000000000000",
      )
    end
  end
end
