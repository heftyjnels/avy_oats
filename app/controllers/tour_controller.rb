class TourController < ApplicationController
  layout "tour"

  def show
    @snapshot = Tour::Snapshot.fetch
  end
end
