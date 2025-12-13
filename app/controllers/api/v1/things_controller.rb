module Api::V1
  class ThingsController < Api::ApiController
    def index
      rel = Thing.all
      rel = rel.roots if params[:roots_only]
      rel = rel.where2(own_tags: { "template" => true }) if params[:templates_only]
      rel = rel.where2(tags: params[:query].to_unsafe_h) if params[:query].present?

      @things = rel
      @sliced_data = sliced_json(@things)
    end

    def show
      @thing = Thing.find(params[:id])
    end
  end
end
