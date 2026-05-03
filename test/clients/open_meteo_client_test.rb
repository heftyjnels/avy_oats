require "test_helper"

class OpenMeteoClientTest < ActiveSupport::TestCase
  setup do
    @client = OpenMeteoClient.new
  end

  test "hourly_cloud_cover passes the documented query parameters" do
    body = file_fixture("open_meteo_cloud_cover.json").read
    stub_request(:get, %r{https://api\.open-meteo\.com/v1/forecast.*})
      .to_return(status: 200, body: body, headers: {content_type: "application/json"})

    response = @client.hourly_cloud_cover(lat: 40.5829, lon: -111.6556)

    assert response.hourly.cloud_cover.length > 0
    assert_requested :get, %r{https://api\.open-meteo\.com/v1/forecast.*hourly=cloud_cover.*}
    assert_requested :get, %r{https://api\.open-meteo\.com/v1/forecast.*latitude=40\.5829.*}
  end

  test "daily_uv requests uv_index_max" do
    body = file_fixture("open_meteo_uv.json").read
    stub_request(:get, %r{https://api\.open-meteo\.com/v1/forecast.*})
      .to_return(status: 200, body: body, headers: {content_type: "application/json"})

    response = @client.daily_uv(lat: 40.5829, lon: -111.6556)

    assert_equal [7.4], response.daily.uv_index_max.to_a
    assert_requested :get, %r{https://api\.open-meteo\.com/v1/forecast.*daily=uv_index_max.*}
  end

  test "sends User-Agent" do
    stub_request(:get, %r{https://api\.open-meteo\.com/v1/forecast.*})
      .to_return(status: 200, body: "{}", headers: {content_type: "application/json"})

    @client.daily_uv(lat: 40.5829, lon: -111.6556)

    assert_requested(
      :get, %r{https://api\.open-meteo\.com/v1/forecast.*},
      headers: {"User-Agent" => Avyoats::USER_AGENT}
    )
  end
end
