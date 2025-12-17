module Lookups
  extend ActiveSupport::Concern

  JSON_TYPES = [:json, :jsonb]

  included do
    scope :where2, ->(**kwargs) {
      LookupBuilder.parse(self, **kwargs)
    }
  end

  class LookupBuilder
    def self.parse(base_scope, **kwargs)
      new(base_scope).tap do |builder|
        builder.send(:parse, **kwargs)
      end.applied
    end

    def applied
      @applied_scope ||= begin
        q = @current_context[:rel]
        q = q.joins(**@joins) if @joins.present?
        q.where(@clauses.map{|c| "(#{c})" }.join(' AND '), **@injected_vars)
      end
    end

    def self.define_lookup(key, operator = nil, &block)
      raise ArgumentError, "One of operator or block must be provided" unless [operator, block].compact.count == 1
      if operator
        define_lookup(key) do |p|
          " #{operator} #{var_for(p)}"
        end
      else
        define_method("lookup_#{key}", &block)
      end
    end

    define_lookup :eq do |p|
      if p == nil
        " IS NULL"
      else
        " = #{var_for(p)}"
      end
    end

    define_lookup :neq do |p|
      if p == nil
        " IS NOT NULL"
      elsif p.is_a?(Array)
        " NOT IN (#{var_for(p)})"
      else
        " <> #{var_for(p)}"
      end
    end

    define_lookup :key? do |p|
      if p.is_a?(String)
        " ? #{var_for(p)}"
      else
        lookup_present?(p)
      end
    end

    define_lookup :in do |p|

      throw :full_clause, "0=1" if p.blank?
      bits = []
      compacted = p.compact
      if compacted.size < p.size
        bits << "#{sqlize_path} IS NULL"
      end

      if compacted.count == 1
        bits << "#{sqlize_path} = #{var_for(compacted.first)}"
      elsif compacted.any?
        bits << "#{sqlize_path} IN (#{var_for(compacted)})"
      end

      throw :full_clause, bits.join(' OR ')
    end

    define_lookup :present? do |p|
      path = @current_context[:path]
      short_path = path[0..-2]
      key = path.last
      throw :full_clause, "#{!p ? 'NOT' : ''} #{sqlize_path(short_path)} ? #{key}"
    end

    define_lookup :exists? do |p|
      raise ArgumentError, "Can only use '__exists?' on tables" if current_column
      pcontext = @current_context[:previous_table]

      opts = p.is_a?(Hash) ? p : {}
      pcontext[:rel] = pcontext[:rel].where_exists(@current_context[:root_key], **opts)
      throw :full_clause, nil
    end

    define_lookup :overlaps do |p|
      case current_column&.type
      when *JSON_TYPES
        throw :full_clause, <<~SQL
          EXISTS (
            select *
            from jsonb_array_elements_text(#{sqlize_path}) as t(x)
            where t.x IN (#{var_for(p, type: nil)})
          )
        SQL
      else
        " && ARRAY[#{var_for(p, type: nil)}]"
      end
    end

    define_lookup :contains, "@>"
    define_lookup :contained_by, "<@"
    define_lookup :gt, ">"
    define_lookup :gte, ">="
    define_lookup :lt, "<"
    define_lookup :lte, "<="

    protected

    def initialize(scope)
      @scope = scope
      @clauses = []
      @joins = {}

      @injected_vars = {}
      @injected_cache_map = {}

      @current_context = {
        root_key: nil,
        path: [],
        model: scope.model,
        rel: scope,
      }
    end

    def parse(**kwargs)
      kwargs.each do |hkey, value|
        key, lookup = hkey.to_s.split('__')
        push(key) do
          if lookup.blank? && value.is_a?(Hash)
            parse(**value)
          else
            clause = catch :full_clause do
              lookup ||= value.is_a?(Array) && value.present? ? 'in' : 'eq'
              clause = parse_lookup(lookup, value)
              full_key = sqlize_path
              "#{full_key}#{clause}"
            end
            @clauses.push(clause) if clause.present?
          end
        end
      end
    end

    def push(key)
      old_context = @current_context

      if key.present?
        new_context = old_context.deep_dup

        # JSONB field access
        if old_context[:path].present?
          key = "'#{key}'"
        else
          assocs_by_name = new_context[:model].reflect_on_all_associations.index_by(&:name)
          assoc = assocs_by_name[key.to_sym]
          if assoc
            new_context[:root_key] = key
            new_context[:model] = assoc.klass
            new_context[:rel] = assoc.klass.all
            new_context[:previous_table] = old_context
            key = []
          else
            ensure_join
          end
        end

        key = [*old_context[:path], key] unless key.is_a?(Array)
        new_context[:path] = key

        @current_context = new_context
      end

      yield
    ensure
      if @current_context[:previous_table]
        old_context[:rel] = old_context[:rel].merge(@current_context[:rel])
      end
      @current_context = old_context
    end

    def parse_lookup(lookup, param)
      send(:"lookup_#{lookup}", param)
    end

    def var_for(value, type = current_column&.type)
      return value if value.is_a?(Arel::Nodes::SqlLiteral)

      key = :"var_#{@injected_vars.size}"

      case type
      when *JSON_TYPES
        value = Arel.sql(ActiveRecord::Base.connection.quote(value.to_json))
      end

      @injected_cache_map[value] ||= begin
        @injected_vars[key] = value
        ":#{key}"
      end
    end

    def ensure_join
      trail = table_trail
      trail.shift # Remove the start table
      joins = @joins
      trail.each do |t|
        joins[t.to_sym] ||= {}
        joins = joins[t.to_sym]
      end
    end

    def table_trail
      trail = []
      context = @current_context
      while context
        trail.unshift(context[:root_key])
        context = context[:previous_table]
      end
      trail
    end

    def current_column
      @current_context[:model].columns_hash[@current_context[:path][0]]
    end

    def sqlize_path(key = @current_context[:path])
      key = key.join(' -> ')
      [@current_context[:root_key], key].compact.join('.')
    end
  end
end
