module Avyoats
  # Snowbird Mountain Resort coordinates (lat/lon, decimal degrees)
  SNOWBIRD_LAT = 40.5829
  SNOWBIRD_LON = -111.6556

  # Closest NWS station to Snowbird that publishes hourly observations.
  # KU42 is the public weather station at the entrance to Little Cottonwood
  # Canyon and consistently reports temperature, wind speed, and wind direction.
  # Override per-environment if a better station is identified.
  NWS_STATION_ID = ENV.fetch("AVYOATS_NWS_STATION", "KU42")

  # Sent on every outbound API request. Both UAC and NWS require a meaningful
  # User-Agent and reject anonymous traffic.
  USER_AGENT = ENV.fetch(
    "AVYOATS_USER_AGENT",
    "avyoats.com/1.0 (contact@avyoats.com)"
  )

  TIME_ZONE = "America/Denver"

  module Cameras
    extend self

    def all
      @all ||= Rails.application.config_for(:cameras).deep_symbolize_keys
    end

    def little_cottonwood = all[:little_cottonwood] || []

    def big_cottonwood = all[:big_cottonwood] || []

    def resorts = all[:resorts] || []

    def reload!
      @all = nil
      all
    end
  end
end
