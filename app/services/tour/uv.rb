module Tour
  # Normalizes the Open-Meteo daily UV index forecast into a single-day card.
  # We deliberately surface this as a forecast value (not a station observation)
  # because Open-Meteo and EPA both treat UV index as a daily forecast product.
  Uv = Data.define(:date, :uv_max, :category) do
    CATEGORIES = [
      [0..2, "Low"],
      [3..5, "Moderate"],
      [6..7, "High"],
      [8..10, "Very High"],
      [11..Float::INFINITY, "Extreme"]
    ].freeze

    def self.from_response(response)
      data = response_to_h(response)
      daily = data["daily"] || {}
      dates = Array(daily["time"])
      values = Array(daily["uv_index_max"])

      return if dates.empty? || values.empty?

      raw_value = values.first
      return if raw_value.nil?

      uv_max = raw_value.to_f.round(1)

      new(
        date: parse_date(dates.first),
        uv_max: uv_max,
        category: categorize(uv_max)
      )
    end

    def self.categorize(value)
      CATEGORIES.find { |range, _| range.cover?(value) }&.last || "Unknown"
    end

    def self.parse_date(value)
      return if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError
      nil
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

    def date_label
      return "Today" if date.blank? || date == Date.current

      date.strftime("%a %b %-d")
    end
  end
end
