module Api::V1
  class ScannersController < Api::ApiController
    def index
      @scanners = Scanner.all
    end

    def show
      @scanner = Scanner.find(params[:id])
    end

    def known_models
      obj = {}

      ScannerTranslator::HANDLERS_BY_MODEL.each do |model, handler|
        obj[model] = {
          url_base: handler.url_base,
          configuration: handler.options,
          endpoints: handler.endpoints.map do |type, path_handlers|
            [type, path_handlers.keys]
          end.to_h,
        }
      end

      render json: obj
    end
  end
end
