class ScanLog < ApplicationRecord
  belongs_to :object, polymorphic: true, optional: true
  belongs_to :scanner
  after_create_commit {
    ScanLogChannel.broadcast_to(self.class, self.as_json.merge({ _html: ApplicationController.renderer.render(partial: "partials/log_toast", locals: { scan_log: self }) }) )
  }
end
