require "test_helper"

class UacForecastClientTest < ActiveSupport::TestCase
  setup do
    @client = UacForecastClient.new
  end

  test "salt_lake hits the documented region URL" do
    body = file_fixture("uac_salt_lake.json").read
    stub_request(:get, "https://utahavalanchecenter.org/forecast/salt-lake/json")
      .to_return(status: 200, body: body, headers: {content_type: "application/json"})

    response = @client.salt_lake

    assert_equal "salt-lake", response.region
    assert_equal 8, response.overall_danger_rose.length
  end

  test "sends the configured User-Agent header" do
    stub_request(:get, "https://utahavalanchecenter.org/forecast/salt-lake/json")
      .to_return(status: 200, body: "{}", headers: {content_type: "application/json"})

    @client.salt_lake

    assert_requested(
      :get, "https://utahavalanchecenter.org/forecast/salt-lake/json",
      headers: {"User-Agent" => Avyoats::USER_AGENT}
    )
  end

  test "raises on unknown region" do
    assert_raises(ArgumentError) { @client.forecast("not-a-region") }
  end

  test "propagates HTTP errors as ApplicationClient::Error subclasses" do
    stub_request(:get, "https://utahavalanchecenter.org/forecast/salt-lake/json")
      .to_return(status: 500)

    assert_raises(ApplicationClient::InternalError) { @client.salt_lake }
  end
end
