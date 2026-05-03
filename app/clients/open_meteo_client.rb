class OpenMeteoClient < ApplicationClient
  BASE_URI = "https://api.open-meteo.com"

  # Hourly cloud cover forecast (percent). Using a +/- 18 hour window keeps the
  # payload tiny while giving the page enough surrounding context.
  def hourly_cloud_cover(lat:, lon:)
    get(
      "/v1/forecast",
      query: {
        latitude: lat,
        longitude: lon,
        hourly: "cloud_cover",
        timezone: Avyoats::TIME_ZONE,
        forecast_days: 2,
        past_days: 1
      }
    )
  end

  # Daily UV index forecast. Open-Meteo and EPA both treat UV index as a daily
  # forecast product, not a station observation, so we surface it that way.
  def daily_uv(lat:, lon:)
    get(
      "/v1/forecast",
      query: {
        latitude: lat,
        longitude: lon,
        daily: "uv_index_max",
        timezone: Avyoats::TIME_ZONE,
        forecast_days: 1
      }
    )
  end

  def default_headers
    super.merge("User-Agent" => Avyoats::USER_AGENT)
  end

  def authorization_header = {}

  def open_timeout = 3

  def read_timeout = 5
end
