module ArangoLookups
  extend ActiveSupport::Concern

  JSON_TYPES = [:json, :jsonb]

  included do
    scope :where2, ->(**kwargs) {
      LookupBuilder.parse(self, **kwargs)
    }
  end

  class LookupBuilder
    def self.parse(**kwargs)
      new().tap do |builder|
        builder.send(:parse, **kwargs)
      end.build_query
    end

    def build_query
      ast = @current_context[:ast]
      # puts YAML.dump(ast)
      return render_ast(ast)
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
        "IS_NULL(<KEY>)"
      else
        "== #{var_for(p)}"
      end
    end

    define_lookup :neq do |p|
      if p == nil
        "!IS_NULL(<KEY>)"
      elsif p.is_a?(Array)
        " NOT IN (#{var_for(p)})"
      else
        "!= #{var_for(p)}"
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
      gnode = @current_context[:ast]
      pnode = gnode[:parent_ast]

      logic = p ? '> 0' : '< 1'
      ast_child!('filter', {
        clause: ->(k) {
          "LENGTH(#{gnode[:vname]}) #{logic}"
        }
      }, node: pnode)

      nil
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

    def initialize()
      @injected_vars = {}
      @injected_cache_map = {}

      @current_context = {
        ast: { type: 'root', vname: "t", children: {}, filters: [] },
        path: ["t"],
      }
    end

    # { type: 'root' | 'scalar' | 'graph' | 'pointer', vname: "", filters: [], children: {} }

    def parse(**kwargs)
      kwargs.each do |hkey, value|
        key, lookup = hkey.to_s.split('__')
        if lookup.blank? && value.is_a?(Hash)
          push(key) do
            parse(**value)
          end
        else
          lookup ||= value.is_a?(Array) && value.present? ? 'in' : 'eq'
          clause = parse_lookup(lookup, value)
          ast_child!('filter', { key: key, clause: clause }) if clause.present?
        end
      end
    end

    def render_ast(ast, lines = [])
      t = ast[:type]
      case ast[:type]
      when 'root'
        lines << "FOR t IN Things"
        render_ast_children(ast, lines)
        lines << "RETURN t"
      when 'scalar', 'graph', 'pointer'
        render_ast_condition(ast, lines)
      when 'filter'
        lines << "FILTER #{render_filter_clause(ast)}"
      end
      lines.join("\n")
    end

    def render_ast_condition(ast, lines)
      ast[:vname] ||= "filt_#{lines.size + 1}_val"
      qual = "#{ast[:parent_ast][:vname]}.#{ast[:key]}"

      case ast[:type]
      when 'scalar'
        lines << "LET #{ast[:vname]} = #{qual}"
        render_ast_children(ast, lines)
      when 'graph', 'pointer'
        parent_doc = traverse_up(ast[:parent_ast]) { |n| throw :found if %w[root graph pointer].include?(n[:type]) }

        scalar_filter_nodes = []
        traverse(ast[:children].values) do |node|
          case node[:type]
          when 'filter'
            scalar_filter_nodes << node
          when 'scalar'
          else
            throw :continue
          end
          node[:children].values
        end

        clauses = scalar_filter_nodes.map do |sf_node|
          key = traverse_up(sf_node, to: ast).map { |n| n[:key]}.reverse
          key.shift
          key.unshift(ast[:vname])
          "FILTER #{render_filter_clause(sf_node, key: key)}"
        end

        graph_clause = <<~AQL
          FOR #{ast[:vname]}, #{ast[:vname]}_edge, #{ast[:vname]}_path IN 1..8 OUTBOUND #{parent_doc[:vname]} GRAPH 'ThingGraph'
            PRUNE #{ast[:vname]}_edge.type != '#{ast[:key]}'
            FILTER #{ast[:vname]}_edge.type != '#{ast[:key]}'
            #{clauses.join("\n")}
            RETURN DISTINCT #{ast[:vname]}
        AQL
        lines << "LET #{ast[:vname]} = (#{graph_clause.strip})"
        lines[-1] += "[0]" if ast[:type] == 'pointer'
        # ... Non-Scalar filters can render here
        # TODO Cleanup redundant filter emit
        render_ast_children(ast, lines)
      end
    end

    def render_ast_children(ast, lines, only: nil, except: nil)
      ast[:children].each_value do |child|
        next if only && !only.include?(child[:key])
        next if except && except.include?(child[:key])
        render_ast(child, lines)
      end
      lines.join("\n")
    end

    def render_filter_clause(filter, key: nil)
      key ||= "#{filter[:parent_ast][:vname]}.#{filter[:key]}"
      key = key.join('.') if key.is_a?(Array)

      clause = filter[:clause]
      if clause.is_a?(Proc)
        clause.call(key)
      elsif clause.include?("<KEY>")
        clause.gsub("<KEY>", key)
      else
        "#{key} #{clause}"
      end
    end

    def traverse_up(ast, to: nil)
      return to_enum(:traverse_up, ast, to:) unless block_given?

      traverse(ast, mode: :dfs) do |node|
        yield node
        throw :found if node == to
        throw :found unless node[:parent_ast]
        node[:parent_ast]
      end
    end

    def traverse_down(ast, **kwargs, &blk)
      traverse(ast, **kwargs) do |node|
        yield(node)
        node[:children].values
      end
    end

    def traverse(entry, mode: :bfs, &blk)
      return to_enum(:traverse, entry, mode: mode) unless block_given?

      queue = Array.wrap(entry)
      while queue.any?
        node = mode == :bfs ? queue.shift : queue.pop
        catch :continue do
          return catch :found do
            children = yield(node)
            Array.wrap(children).compact.each do |child|
              queue << child
            end
            throw :continue
          end || node
        end
      end
    end

    def push(key)
      old_context = @current_context

      if key.present?
        new_context = old_context.dup

        key = [*old_context[:path], key] unless key.is_a?(Array)
        new_context[:path] = key

        k = key.last.to_s
        pk = /^(\w+)(?::(\w+))?(?:\[([\w|\*]+)\])?$/.match(k)

        # TODO Move Scalars up to nearest root/graph/pointer parent
        new_context[:ast] = ast_child!(pk[2] || 'scalar', { key: pk[1] }, key: key.last)

        @current_context = new_context
      end

      yield
    ensure
      @current_context = old_context
    end

    def ast_child!(type, base = {}, key: SecureRandom.hex(4), node: @current_context[:ast], &blk)
      node[:children][key] ||= {
        parent_ast: node,
        children: {},
        **base,
        **blk&.call || {},
        type: type.to_s,
      }
      node[:children][key]
    end

    def parse_lookup(lookup, param)
      send(:"lookup_#{lookup}", param)
    end

    def ensure_var(vfor)
      m = /^(\w+)(?::(\w+))?(?:\[([\w|\*]+)\])?$/.match(vfor)
      raise ArgumentError, "Invalid var format: #{vfor}" unless m
      k = "#{m[1]}_#{m[2] || 'scalar'}_#{SecureRandom.hex(4)}"

      @current_context[:modifier] = m[3]

      path = [*@current_context[:var_path], k]
      @written_vars[path] ||= begin
        getter = case m[2]
        when 'graph'
          <<~AQL
            ()
          AQL
        when 'pointer'
          <<~AQL
            ()
          AQL
        when 'graph'
          <<~AQL
            ()
          AQL
        when "", "scalar", nil
          "#{path[-2]}.#{m[1]}"
        else
          raise ArgumentError, "Unknown var type: #{m[2]}"
        end
        @clauses << "LET #{k} = #{getter}"
        k
      end
    end

    def var_for(value)
      key = :"var_#{@injected_vars.size}"

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
  end
end
