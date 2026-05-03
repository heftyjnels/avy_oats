require "test_helper"

class NwsObservationsClientTest < ActiveSupport::TestCase
  setup do
    @client = NwsObservationsClient.new
  end

  test "recent fetches the station observations endpoint with a start window" do
    body = file_fixture("nws_observations.json").read

    stub_request(:get, %r{https://api\.weather\.gov/stations/KU42/observations\?start=.*})
      .to_return(status: 200, body: body, headers: {content_type: "application/geo+json"})

    response = @client.recent("KU42", hours: 24)

    assert_equal 3, response.features.length
  end

  test "sends User-Agent and geo+json Accept" do
    stub_request(:get, %r{https://api\.weather\.gov/stations/KU42/observations.*})
      .to_return(status: 200, body: "{}", headers: {content_type: "application/geo+json"})

    @client.recent("KU42")

    assert_requested(
      :get, %r{https://api\.weather\.gov/stations/KU42/observations.*},
      headers: {
        "User-Agent" => Avyoats::USER_AGENT,
        "Accept" => "application/geo+json"
      }
    )
  end

  test "latest hits the documented endpoint" do
    stub_request(:get, "https://api.weather.gov/stations/KU42/observations/latest")
      .to_return(status: 200, body: "{}", headers: {content_type: "application/geo+json"})

    @client.latest("KU42")

    assert_requested :get, "https://api.weather.gov/stations/KU42/observations/latest"
  end
end
