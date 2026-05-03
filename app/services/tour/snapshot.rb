require "concurrent"

module Tour
  # Aggregates the three external feeds plus the curated camera config into a
  # single value object the view can render. Each source fails independently:
  # if one provider returns an error the others still render and the failed
  # section degrades to a friendly "data temporarily unavailable" partial.
  class Snapshot
    Result = Data.define(:avalanche, :weather, :uv, :cameras, :errors, :fetched_at)

    SOURCES = %i[avalanche weather uv].freeze

    def self.fetch(...) = new(...).fetch

    def initialize(
      uac_client: UacForecastClient.new,
      nws_client: NwsObservationsClient.new,
      open_meteo_client: OpenMeteoClient.new
    )
      @uac_client = uac_client
      @nws_client = nws_client
      @open_meteo_client = open_meteo_client
      @errors = {}
    end

    def fetch
      avalanche_future = Concurrent::Promises.future { fetch_avalanche }
      weather_future = Concurrent::Promises.future { fetch_weather }
      uv_future = Concurrent::Promises.future { fetch_uv }

      Result.new(
        avalanche: avalanche_future.value!,
        weather: weather_future.value!,
        uv: uv_future.value!,
        cameras: cameras,
        errors: @errors,
        fetched_at: Time.current
      )
    end

    private

    def fetch_avalanche
      Avalanche.from_response(@uac_client.salt_lake)
    rescue ApplicationClient::Error => e
      record_error(:avalanche, e)
      nil
    end

    def fetch_weather
      observations = @nws_client.recent(Avyoats::NWS_STATION_ID, hours: 24)
      cloud_cover = safe_cloud_cover

      Weather.from_responses(observations:, cloud_cover:)
    rescue ApplicationClient::Error => e
      record_error(:weather, e)
      nil
    end

    def safe_cloud_cover
      @open_meteo_client.hourly_cloud_cover(
        lat: Avyoats::SNOWBIRD_LAT,
        lon: Avyoats::SNOWBIRD_LON
      )
    rescue ApplicationClient::Error => e
      record_error(:cloud_cover, e)
      nil
    end

    def fetch_uv
      Uv.from_response(
        @open_meteo_client.daily_uv(
          lat: Avyoats::SNOWBIRD_LAT,
          lon: Avyoats::SNOWBIRD_LON
        )
      )
    rescue ApplicationClient::Error => e
      record_error(:uv, e)
      nil
    end

    def cameras
      {
        little_cottonwood: Avyoats::Cameras.little_cottonwood,
        big_cottonwood: Avyoats::Cameras.big_cottonwood,
        resorts: Avyoats::Cameras.resorts
      }
    end

    def record_error(source, error)
      Rails.logger.warn(
        "[Tour::Snapshot] #{source} failed: #{error.class.name} #{error.message.to_s.truncate(200)}"
      )
      @errors[source] = error.class.name.demodulize
    end
  end
end
