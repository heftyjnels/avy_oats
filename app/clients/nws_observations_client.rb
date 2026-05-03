class NwsObservationsClient < ApplicationClient
  BASE_URI = "https://api.weather.gov"

  # NWS responses use `application/geo+json` which the default ApplicationClient
  # parser table doesn't register. Reuse the JSON parser so callers can use
  # method-style access on the response body.
  Response::PARSER["application/geo+json"] = Response::PARSER["application/json"]

  # The NWS API rejects requests without a meaningful User-Agent identifying
  # the application and a contact channel. See https://www.weather.gov/documentation/services-web-api.
  def latest(station_id)
    get("/stations/#{station_id}/observations/latest")
  end

  def recent(station_id, hours: 24)
    get(
      "/stations/#{station_id}/observations",
      query: {start: hours.hours.ago.utc.iso8601}
    )
  end

  def station(station_id)
    get("/stations/#{station_id}")
  end

  def default_headers
    super.merge(
      "User-Agent" => Avyoats::USER_AGENT,
      "Accept" => "application/geo+json"
    )
  end

  def authorization_header = {}

  def open_timeout = 3

  def read_timeout = 5
end
