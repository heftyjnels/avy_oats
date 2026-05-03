module Tour
  # Normalizes NWS station observations and Open-Meteo cloud cover forecasts
  # into time-series ready for Chart.js.
  #
  # NWS observation properties expose values as `{value:, unitCode:}` hashes.
  # We convert temperature to Fahrenheit and wind speed to mph (NWS reports SI).
  Weather = Data.define(
    :station_id,
    :latest_at,
    :temperature_series,
    :wind_speed_series,
    :wind_direction_series,
    :cloud_cover_series,
    :missing_metrics
  ) do
    METRICS = %i[temperature wind_speed wind_direction cloud_cover].freeze

    def self.from_responses(observations:, cloud_cover: nil)
      data = response_to_h(observations)
      features = Array(data["features"])
      points = features.map { |f| f["properties"] }.compact.reverse

      temperature = points.filter_map { |p| time_value(p, "temperature") { |c| c_to_f(c) } }
      wind_speed = points.filter_map { |p| time_value(p, "windSpeed") { |kmh| kmh_to_mph(kmh) } }
      wind_direction = points.filter_map { |p| time_value(p, "windDirection") }

      cloud = cloud_cover_series(cloud_cover)

      missing = []
      missing << :temperature if temperature.empty?
      missing << :wind_speed if wind_speed.empty?
      missing << :wind_direction if wind_direction.empty?
      missing << :cloud_cover if cloud.empty?

      new(
        station_id: Avyoats::NWS_STATION_ID,
        latest_at: temperature.last&.dig(:t) || wind_speed.last&.dig(:t),
        temperature_series: temperature,
        wind_speed_series: wind_speed,
        wind_direction_series: wind_direction,
        cloud_cover_series: cloud,
        missing_metrics: missing
      )
    end

    def self.cloud_cover_series(response)
      data = response_to_h(response)
      hourly = data["hourly"] || {}
      times = Array(hourly["time"])
      values = Array(hourly["cloud_cover"])

      now = Time.current
      window_start = now - 6.hours
      window_end = now + 18.hours

      times.zip(values).filter_map do |t, v|
        next if t.blank? || v.nil?

        parsed = Time.zone.parse(t.to_s)
        next unless parsed&.between?(window_start, window_end)

        {t: parsed, v: v.to_f}
      end
    end

    def self.time_value(properties, key)
      timestamp = properties["timestamp"]
      raw = properties.dig(key, "value")
      return if timestamp.blank? || raw.nil?

      converted = block_given? ? yield(raw.to_f) : raw.to_f
      {t: Time.zone.parse(timestamp.to_s), v: converted.round(2)}
    rescue ArgumentError
      nil
    end

    def self.c_to_f(celsius) = (celsius * 9.0 / 5.0) + 32

    def self.kmh_to_mph(kmh) = kmh * 0.621371

    def self.response_to_h(response)
      return {} if response.nil?
      return response if response.is_a?(Hash)
      return response.parsed_body if response.respond_to?(:parsed_body)
      return JSON.parse(response.body.to_s) if response.respond_to?(:body)

      {}
    rescue JSON::ParserError
      {}
    end

    def has?(metric) = !missing_metrics.include?(metric)

    def latest_temperature = temperature_series.last&.dig(:v)

    def latest_wind_speed = wind_speed_series.last&.dig(:v)

    def latest_wind_direction = wind_direction_series.last&.dig(:v)

    def latest_label
      return if latest_at.blank?

      latest_at.in_time_zone(Avyoats::TIME_ZONE).strftime("%-l:%M %p %Z")
    end
  end
end
