class Thing < ApplicationRecord
  include JsonbGraph

  has_paper_trail(
    only: %i[own_tags],
    skip: %i[id tags created_at updated_at],
  )

  # TODO Consider ArangoDB instead of Postgres for this model
  #   - We'd probably still keep the own_tags and the cached tags separate
  #     - It would be nice to do the tag merging as part of the AQL, but it
  #         wouldn't understand the inheritable/non-inheritable distinction
  #     - We could potentially have `own_tags` and `private_tags`, then live-calculate
  #         inheritance from there
  #     - Would Foxx be useful here?
  #   - We could adapt the `lookups` language pretty easily
  #   - With Arango's graph traversals, `JsonbGraph` would be a given
  #       (though we would need to populate the Graph edges)
  #   - Arango could also fulfil located-in queries quite easily
  #   - Multi-tenanting could also be pretty easy
  #
  #   For now, let's keep with Postgres, but we should not call any ActiceRecord methods
  #     from outside this model class, thus keeping it opaque/easily swappable.

  # before_save :compute_effective_tags
  after_save :refresh_inheritor_tags, if: :own_tags_changed?

  scope :roots, ->{
    where2(own_tags: { "implements" => [nil, []] })
  }

  def self.query(*args, own: {}, **tags)
    q = {
      tags: tags,
    }
    q[:own_tags] = own if own.present?
    args.each do |a|
      case a
      when :root
        q.merge!(own_tags: { "implements" => [nil, []] })
      when Hash
        q[:tags].merge!(a)
      when Symbol
        q[:tags][a] = true
      end
    end
    where2(**q)
  end

  before_save do
    # self.inherits_from = tags["inherits"]
  end

  # ancestry_chain :inherits_from
  # ancestry_chain :belongs_to

  def refresh_inheritor_tags
    refresh_tag_cache!
  end

  def refresh_tag_cache!(force: false)
    # TODO Move this into a job and make it relatively lazy - the only thing we should need the
    #   cached, merged tags for is searching - something that we can be okay with eventual-consistency for.
    #   Will want optimistic locking
    pending_save = Miscellany::BatchProcessor.new(of: 100) do |batch|
      self.class.import(batch,
        validate: false,
        timestamps: false,
        on_duplicate_key_update: [:tags],
      )
    end

    frontier = [self]
    parent_cache = { self.id => self }
    while frontier.any?
      batch = frontier.shift(50)

      modified = batch.select do |current|
        current._refresh_tag_cache_work(parent_cache: parent_cache)
        pending_save << current if current.changed?
        force || current.changed?
      end

      modified.each do |current|
        parent_cache[current.id] = current
      end

      all_directs = Thing.where2(own_tags: { "implements__overlaps" => modified.map(&:id) })
      all_directs.find_each do |di|
        frontier << di
      end
    end

    pending_save.flush
  end

  def direct_inheritors
    Thing.where2(own_tags: { "implements__contains" => [id] })
  end

  def tags
    # TODO Compute live if the cache is stale
    attributes["tags"]
  end

  define_graph_connection :implements
  define_graph_connection :located_in

  protected

  def _refresh_tag_cache_work(parent_cache: {})
    parent_ids = own_tags["implements"] || []

    Thing.where(id: parent_ids.reject{ |id| parent_cache.key?(id) }).find_each do |parent|
      parent_cache[parent.id] = parent
    end

    parents = parent_ids.map{ |id| parent_cache[id] }
    # TODO Remove non-inheritable tags
    tag_sets = [*parents.map(&:tags), own_tags]

    self.tags = tag_sets.reduce { |acc, tags| acc.merge(tags) }
  end
end
