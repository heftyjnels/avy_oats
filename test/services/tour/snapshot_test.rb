require "test_helper"

module Tour
  class SnapshotTest < ActiveSupport::TestCase
    setup do
      stub_request(:get, "https://utahavalanchecenter.org/forecast/salt-lake/json")
        .to_return(status: 200, body: file_fixture("uac_salt_lake.json").read, headers: {content_type: "application/json"})

      stub_request(:get, %r{https://api\.weather\.gov/stations/.*/observations.*})
        .to_return(status: 200, body: file_fixture("nws_observations.json").read, headers: {content_type: "application/geo+json"})

      stub_request(:get, %r{https://api\.open-meteo\.com/v1/forecast.*hourly=cloud_cover.*})
        .to_return(status: 200, body: file_fixture("open_meteo_cloud_cover.json").read, headers: {content_type: "application/json"})

      stub_request(:get, %r{https://api\.open-meteo\.com/v1/forecast.*daily=uv_index_max.*})
        .to_return(status: 200, body: file_fixture("open_meteo_uv.json").read, headers: {content_type: "application/json"})
    end

    test "fetch returns avalanche, weather, uv, and cameras when all sources succeed" do
      result = Snapshot.fetch

      assert_kind_of Avalanche, result.avalanche
      assert_kind_of Weather, result.weather
      assert_kind_of Uv, result.uv
      assert_includes result.cameras.keys, :little_cottonwood
      assert_empty result.errors
      assert_kind_of Time, result.fetched_at
    end

    test "avalanche failure does not block other sections" do
      stub_request(:get, "https://utahavalanchecenter.org/forecast/salt-lake/json")
        .to_return(status: 500)

      result = Snapshot.fetch

      assert_nil result.avalanche
      assert_kind_of Weather, result.weather
      assert_kind_of Uv, result.uv
      assert_includes result.errors.keys, :avalanche
    end

    test "weather failure leaves UV intact" do
      stub_request(:get, %r{https://api\.weather\.gov/stations/.*/observations.*})
        .to_return(status: 503)

      result = Snapshot.fetch

      assert_nil result.weather
      assert_kind_of Uv, result.uv
      assert_includes result.errors.keys, :weather
    end

    test "uv failure leaves the rest intact" do
      stub_request(:get, %r{https://api\.open-meteo\.com/v1/forecast.*daily=uv_index_max.*})
        .to_return(status: 500)

      result = Snapshot.fetch

      assert_kind_of Avalanche, result.avalanche
      assert_kind_of Weather, result.weather
      assert_nil result.uv
      assert_includes result.errors.keys, :uv
    end

    test "cloud cover failure still produces a weather struct" do
      stub_request(:get, %r{https://api\.open-meteo\.com/v1/forecast.*hourly=cloud_cover.*})
        .to_return(status: 500)

      result = Snapshot.fetch

      assert_kind_of Weather, result.weather
      assert_includes result.weather.missing_metrics, :cloud_cover
      assert_includes result.errors.keys, :cloud_cover
    end
  end
end
