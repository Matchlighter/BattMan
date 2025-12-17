module Api::V1
  class ThingsController < Api::ApiController
    def index
      filters = []
      filters << :root if params[:roots_only]
      filters << { own: { template: true } } if params[:templates_only]
      filters << params[:query].to_unsafe_h if params[:query].present?

      @things = Thing.query(*filters)
      @sliced_data = sliced_json(@things)
    end

    def show
      @thing = Thing.find(params[:id])
    end
  end
end
