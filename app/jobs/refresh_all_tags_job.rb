class RefreshAllTagsJob < ApplicationJob
  queue_as :default

  def perform()
    Thing.roots.each do |root|
      root.refresh_tag_cache!(force: true)
    end
  end
end
