class UacForecastClient < ApplicationClient
  BASE_URI = "https://utahavalanchecenter.org"

  # UAC asks integrators to send a meaningful User-Agent and to poll politely.
  # Forecasts are typically issued between 5 and 8 a.m. and rarely change after.
  REGIONS = %w[salt-lake park-city ogden provo logan moab uintas skyline abajos].freeze

  def salt_lake = forecast("salt-lake")

  def forecast(region)
    raise ArgumentError, "unknown UAC region: #{region}" unless REGIONS.include?(region)

    get("/forecast/#{region}/json")
  end

  def default_headers
    super.merge("User-Agent" => Avyoats::USER_AGENT)
  end

  def authorization_header = {}

  def open_timeout = 3

  def read_timeout = 5
end
