module Tour
  # Normalizes the UAC Salt Lake forecast JSON into the shape the view uses.
  #
  # Per UAC docs, `overall_danger_rose` is an 8-element array starting at the
  # highest-elevation north aspect and proceeding clockwise; values are on the
  # 0..10 danger scale. We expose the rose as a list of {aspect, value, label}
  # triples so the SVG controller can render without re-deriving directions.
  Avalanche = Data.define(
    :overall_danger,
    :overall_danger_label,
    :forecast_issued_at,
    :forecaster,
    :rose,
    :bottom_line,
    :forecast_url
  ) do
    ASPECTS = %w[N NE E SE S SW W NW].freeze

    DANGER_LABELS = {
      0 => "No Rating",
      1 => "Low",
      2 => "Low",
      3 => "Moderate",
      4 => "Moderate",
      5 => "Considerable",
      6 => "Considerable",
      7 => "High",
      8 => "High",
      9 => "Extreme",
      10 => "Extreme"
    }.freeze

    def self.from_response(response)
      data = response_to_h(response)
      return if data.blank?

      rose_values = Array(data["overall_danger_rose"])
      rose = ASPECTS.each_with_index.map do |aspect, i|
        value = rose_values[i].to_i
        {aspect: aspect, value: value, label: DANGER_LABELS.fetch(value, "Unknown")}
      end

      overall = rose.map { |w| w[:value] }.max.to_i
      issued = parse_time(data["forecast_issued_at"] || data["forecast_issued"])

      new(
        overall_danger: overall,
        overall_danger_label: DANGER_LABELS.fetch(overall, "Unknown"),
        forecast_issued_at: issued,
        forecaster: data["forecaster"],
        rose: rose,
        bottom_line: data["bottom_line"].presence,
        forecast_url: data["forecast_url"].presence || "https://utahavalanchecenter.org/forecast/salt-lake"
      )
    end

    def self.response_to_h(response)
      return {} if response.nil?
      return response if response.is_a?(Hash)
      return response.parsed_body if response.respond_to?(:parsed_body)
      return JSON.parse(response.body.to_s) if response.respond_to?(:body)

      {}
    rescue JSON::ParserError
      {}
    end

    def self.parse_time(value)
      return if value.blank?

      case value
      when Time, DateTime, ActiveSupport::TimeWithZone
        value
      when Integer
        Time.zone.at(value)
      else
        Time.zone.parse(value.to_s)
      end
    rescue ArgumentError
      nil
    end

    def issued_label
      return "Forecast unavailable" if forecast_issued_at.blank?

      forecast_issued_at.in_time_zone(Avyoats::TIME_ZONE).strftime("%a %b %-d, %-l:%M %p %Z")
    end
  end
end
