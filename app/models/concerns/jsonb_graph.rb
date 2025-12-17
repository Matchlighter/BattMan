module JsonbGraph
  extend ActiveSupport::Concern

  class_methods do
    def define_graph_connection(name)
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{name}_things
          load_graph_connections!(:"#{name}") unless defined?(@_#{name}_things)
          @_#{name}_things
        end
      RUBY
    end
  end

  protected

  def load_graph_connections!(key)
    records = auto_include_context.models

    all_records = records.index_by(&:id)
    all_implements = records.map{ |r| r.own_tags["#{key}"] || [] }.flatten.uniq
    all_implements -= records.map(&:id)

    if all_implements.present?
      quoted_implements = all_implements.map{ |id| self.class.connection.quote(id) }.join(", ")
      parent_things = self.class.from(<<~SQL)
        (
          WITH RECURSIVE parents_cte AS (
              SELECT things.* FROM #{self.class.quoted_table_name} things WHERE things.id IN (#{quoted_implements})
              UNION
              SELECT things.* FROM #{self.class.quoted_table_name} things
                INNER JOIN parents_cte p ON p.own_tags->'#{key}' ? things.id::text
          )
          SELECT * FROM parents_cte
        ) things
      SQL
      all_records.merge!(parent_things.index_by(&:id))
    end

    all_records.each do |id, record|
      impls = record.own_tags["#{key}"] || []
      parent_things = impls.map{ |pid| all_records[pid] }.compact
      record.instance_variable_set(:"@_#{key}_things", parent_things)
    end
  end
end