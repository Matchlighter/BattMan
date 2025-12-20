module ArangoLookups
  extend ActiveSupport::Concern

  JSON_TYPES = [:json, :jsonb]

  included do
    scope :where2, ->(**kwargs) {
      LookupBuilder.parse(self, **kwargs)
    }
  end

  class LookupBuilder
    def self.parse(*args, **kwargs)
      new(*args, kwargs).aql
    end

    def ast
      @parsed ||= parse(**@filters)
      @root_node
    end

    def print_ast
      puts YAML.dump(ast)
    end

    def aql
      # puts print_ast
      render_ast(ast)
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
      gnode = @current_node
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

    def initialize(coll, filters)
      @coll = coll
      @filters = filters

      @injected_vars = {}
      @injected_cache_map = {}

      @root_node = { type: 'root', collection: @coll, vname: "root_item", children: {}, cost: 0 }
      @current_node = @root_node
    end

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
          if clause.present?
            push key do
              ast_child!('filter', { clause: clause })
            end
          end
        end
      end
    end

    def render_ast(ast = @root_node, lines = [])
      t = ast[:type]
      case ast[:type]
      when 'root'
        lines << "FOR #{ast[:vname]} IN #{ast[:collection]}"
        ast_render_children(ast, lines)
        lines << "RETURN #{ast[:vname]}"
      when 'access'
        ast_render_access(ast, lines)
      when 'filter'
        lines << "FILTER #{ast_render_filter_clause(ast)}"
      end
      lines.join("\n")
    end

    def ast_render_access(ast, lines)
      ast[:vname] ||= "#{ast[:key].gsub(/\W/, '')}_#{SecureRandom.hex(2)}"

      if ast[:match].present?
        parent_doc = traverse_up(ast[:parent_ast]) { |n|
          throw :found if n[:type] == 'root' || (n[:type] == 'access' && n[:type_hint] != 'scalar')
        }

        mode = ast[:match]
        depth = "1"
        if mode.start_with?('^')
          mode = mode[1..-1]
          depth = "1..10"
        end

        magic_graph_clause = <<~AQL
          #{ast[:parent_ast][:vname]}.#{ast[:key]} != "/_GRAPH_/" ? #{ast[:parent_ast][:vname]}.#{ast[:key]} : (
            FOR #{ast[:vname]}, #{ast[:vname]}_edge, #{ast[:vname]}_path IN #{depth} OUTBOUND #{parent_doc[:vname]} GRAPH 'ThingGraph'
              PRUNE #{ast[:vname]}_edge.type != '#{ast[:key]}'
              FILTER #{ast[:vname]}_edge.type != '#{ast[:key]}'
              RETURN DISTINCT #{ast[:vname]}
          )
        AQL

        # TODO: If the final :match filter below doesn't reference the raw_ref, we should just
        #   flatten this LET, merging the filters directly into the graph_clause
        raw_ref = "#{ast[:vname]}_raw"
        lines << "LET #{raw_ref} = #{magic_graph_clause}"

        lines << "LET #{ast[:vname]} = (#{<<~AQL})"
          FOR #{ast[:vname]} IN #{raw_ref}
            #{ast_render_children(ast, [])}
            RETURN #{ast[:vname]}
        AQL

        if mode == "ALL"
          lines << "FILTER LENGTH(#{raw_ref}) == LENGTH(#{ast[:vname]})"
        elsif mode == "ANY"
          lines << "FILTER LENGTH(#{ast[:vname]}) > 0"
        elsif mode.is_a?(Integer) || mode.to_s =~ /^\d+$/
          lines << "FILTER LENGTH(#{ast[:vname]}) == #{mode}"
        end
      else
        ast[:vname] = "#{ast[:parent_ast][:vname]}.#{ast[:key]}"
        # lines << "LET #{ast[:vname]} = #{ast[:parent_ast][:vname]}.#{ast[:key]}"
        ast_render_children(ast, lines)
      end

      # lines[-1] += "[0]" if ast[:type] == 'pointer'
    end

    def ast_render_children(ast, lines, only: nil, except: nil)
      ast[:children].values.sort_by{|c| c[:cost] || 1000000 }.each do |child|
        next if only && !only.include?(child[:type])
        next if except && except.include?(child[:type])
        render_ast(child, lines)
      end
      lines.join("\n")
    end

    def ast_render_filter_clause(filter, key: nil)
      key ||= "#{filter[:parent_ast][:vname]}"
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
      last_node = @current_node
      return yield unless key.present?

      pk = /^([\w\-_]+)(?::(\w+))?(?:\[([\w|\*]+)\])?$/.match(key.to_s)
      @current_node = ast_child!('access', {
        key: pk[1],
        type_hint: pk[2] || 'scalar',
        match: pk[3],
        cost: 1,
      })

      # Float same-document accesses up a little so we can reduce the number of "joins"
      @current_node[:cost] += 10 unless @current_node[:type_hint] == 'scalar'

      yield
    ensure
      last_node[:cost] += @current_node[:cost]
      @current_node = last_node
    end

    def ast_child!(type, base = {}, key: SecureRandom.hex(4), node: @current_node, &blk)
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

    def var_for(value)
      key = :"var_#{@injected_vars.size}"

      @injected_cache_map[value] ||= begin
        @injected_vars[key] = value
        "@#{key}"
      end
    end

    def pretty_print(aql)
      lines = aql.split("\n")
      formatted = []
      indent_level = 0
      indent_keywords = %w[FOR LET]
      dedent_keywords = %w[RETURN FILTER]

      lines.each do |line|
        stripped = line.strip
        next if stripped.empty?

        # Check if this line should dedent first
        if dedent_keywords.any? { |kw| stripped.start_with?(kw) } && indent_level > 0
          indent_level -= 1
        end

        # Add the line with proper indentation
        formatted << ("  " * indent_level) + stripped

        # Check if this line should increase indent for next line
        if indent_keywords.any? { |kw| stripped.start_with?(kw) }
          indent_level += 1
        elsif stripped.start_with?("FILTER") && stripped.include?("(")
          indent_level += 1 if !stripped.include?(")")
        end
      end

      formatted.join("\n")
    end
  end
end
