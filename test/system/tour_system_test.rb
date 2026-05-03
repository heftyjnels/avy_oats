require "application_system_test_case"

class TourSystemTest < ApplicationSystemTestCase
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

  test "renders the tour page with the avalanche rose and camera tiles" do
    visit root_path

    assert_text "avyoats"
    assert_text "Salt Lake region"
    assert_text "Snowbird weather"
    assert_text "UV index"
    assert_selector ".camera-tile", minimum: 4
    assert_selector ".avalanche-rose svg path", minimum: 8
  end
end
