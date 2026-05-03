require "test_helper"

class TourControllerTest < ActionDispatch::IntegrationTest
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

  test "tour page is reachable unauthenticated at the root" do
    get root_path
    assert_response :success
  end

  test "renders the avalanche, weather, uv, and camera sections" do
    get root_path

    assert_select "section[aria-label=?]", "Salt Lake avalanche conditions"
    assert_select "section[aria-label=?]", "Snowbird-area weather"
    assert_select "section[aria-label=?]", "UV forecast"
    assert_select "section.camera-strip", minimum: 3
  end

  test "renders without crashing when all sources fail" do
    stub_request(:get, "https://utahavalanchecenter.org/forecast/salt-lake/json").to_return(status: 500)
    stub_request(:get, %r{https://api\.weather\.gov/.*}).to_return(status: 500)
    stub_request(:get, %r{https://api\.open-meteo\.com/.*}).to_return(status: 500)

    get root_path

    assert_response :success
    assert_select ".source-failed", minimum: 1
  end
end
