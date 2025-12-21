module Lookups
  extend ActiveSupport::Concern

  class ASTNode
    attr_reader :type, :parent, :children

    delegate :[], :[]=, :merge!, to: :@options

    def initialize(type, parent, options)
      @parent = parent
      @type = type
      @options = options
      @children = []
    end

    def child!(type, base = {}, key: SecureRandom.hex(4), &blk)
      node = ASTNode.new(type.to_s, self, {
        **base,
        **blk&.call || {},
      })
      if @current_index
        @children.insert(@current_index + 1, node)
      else
        @children << node
      end
      node
    end

    def iterate_children
      i = 0
      while i < @children.size
        @current_index = i
        @current_child = @children[i]
        yield @current_child
        i += 1
      end
    end

    def root
      node = self
      node = node.parent while node.parent
      node
    end

    def traverse_up(to: nil)
      return to_enum(:traverse_up, to:) unless block_given?

      self.class.traverse(self, mode: :dfs) do |node|
        yield node
        throw :found if node == to
        throw :found unless node.parent
        node.parent
      end
    end

    def traverse_down(to: nil, mode: :bfs)
      return to_enum(:traverse_down, to:) unless block_given?

      self.class.traverse(self, mode: mode) do |node|
        yield node
        throw :found if node == to
        node.children
      end
    end

    def self.traverse(entry, mode: :bfs, &blk)
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
  end

  class LookupsParser
    def self.parse(*args, **kwargs)
      # new(*args, kwargs).print_ast
      new(*args, kwargs).ast
    end

    def ast
      @parsed ||= parse(**@filters)
      @root_node
    end

    def print_ast
      puts YAML.dump(ast)
    end

    protected

    def initialize(filters)
      @filters = filters
      @root_node = ASTNode.new('root', nil, { cost: 0 })
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
          push key do
            @current_node.child!('filter', { lookup: lookup, options: value })
          end
        end
      end
    end

    def push(key)
      last_node = @current_node
      return yield unless key.present?

      pk = /^([\w\-_]+)(?::(\w+))?(?:\[([\w|\*]+)\])?$/.match(key.to_s)
      @current_node = @current_node.child!('access', {
        key: pk[1],
        type_hint: pk[2] || 'scalar',
        match: pk[3],
        cost: 1,
      })

      # Float same-document accesses up a little so we can reduce the number of "joins"
      @current_node[:cost] += 10

      yield
    ensure
      last_node[:cost] += @current_node[:cost]
      @current_node = last_node
    end
  end

  class BaseRenderer
    def initialize(ast)
      @root_node = ast
      @current_node = @root_node

      @injected_vars = {}
      @injected_cache_map = {}
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

    protected

    def var_for(value)
      key = :"var_#{@injected_vars.size}"

      @injected_cache_map[value] ||= begin
        @injected_vars[key] = value
        key
      end
    end

    def parse_lookup(node)
      lookup = node[:lookup]
      param = node[:options]

      mthd = method(:"lookup_#{lookup}")
      args = [param]
      args << node if mthd.arity.abs > 1

      send(:"lookup_#{lookup}", *args)
    end
  end

  class AQLRenderer < BaseRenderer
    def self.parse(coll, **filters)
      root_node = LookupsParser.parse(**filters)
      root_node.merge!({ collection: @coll, vname: "root_item" })
      new(root_node).aql
    end

    def aql
      @rendered ||= render_ast(@root_node)
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

    define_lookup :present? do |p, node|
      pnode = node.parent.parent
      logic = p ? '> 0' : '< 1'
      pnode.child!('filter', {
        raw: "LENGTH(#{pnode[:vname]}) #{logic}",
      })

      nil
    end

    protected

    def var_for(...)
      "@#{super}"
    end

    def render_ast(ast = @root_node, lines = [])
      catch :no_emit do
        case ast.type
        when 'root'
          lines << "FOR #{ast[:vname]} IN #{ast[:collection]}"
          ast_render_children(ast, lines)
          lines << "RETURN #{ast[:vname]}"
        when 'access'
          ast_render_access(ast, lines)
        when 'filter'
          lines << ast_render_filter_clause(ast)
        end
      end
      lines.join("\n")
    end

    def ast_render_access(ast, lines)
      ast[:vname] ||= "#{ast[:key].gsub(/\W/, '')}_#{SecureRandom.hex(2)}"

      if ast[:match].present?
        parent_doc = ast.parent.traverse_up { |n|
          throw :found if n.type == 'root' || (n.type == 'access' && n[:type_hint] != 'scalar')
        }

        mode = ast[:match]
        depth = "1"
        if mode.start_with?('^')
          mode = mode[1..-1]
          depth = "1..10"
        end

        magic_graph_clause = <<~AQL
          #{ast.parent[:vname]}.#{ast[:key]} != "/_GRAPH_/" ? #{ast.parent[:vname]}.#{ast[:key]} : (
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
        ast[:vname] = "#{ast.parent[:vname]}.#{ast[:key]}"
        # lines << "LET #{ast[:vname]} = #{ast.parent[:vname]}.#{ast[:key]}"
        ast_render_children(ast, lines)
      end

      # lines[-1] += "[0]" if ast.type == 'pointer'
    end

    def ast_render_children(ast, lines, only: nil, except: nil)
      ast.iterate_children do |child|
      # ast.children.values.sort_by{|c| c[:cost] || 1000000 }.each do |child|
        next if only && !only.include?(child.type)
        next if except && except.include?(child.type)
        render_ast(child, lines)
      end
      lines.join("\n")
    end

    def ast_render_filter_clause(node, key: nil)
      key ||= "#{node.parent[:vname]}"
      key = key.join('.') if key.is_a?(Array)

      return "FILTER #{node[:raw]}" if node[:raw].present?

      clause = node[:clause] || parse_lookup(node)
      throw :no_emit unless clause.present?

      if clause.include?("<KEY>")
        clause = clause.gsub("<KEY>", key)
      else
        clause = "#{key} #{clause}"
      end

      "FILTER #{clause}"
    end
  end

  class PostgresRenderer < BaseRenderer
    JSON_TYPES = [:json, :jsonb]

    module Concern
      extend ActiveSupport::Concern

      included do
        scope :where2, ->(**kwargs) {
          LookupBuilder.parse(self, **kwargs)
        }
      end
    end

    def self.parse(rel, **filters)
      root_node = LookupsParser.parse(**filters)
      root_node.merge!({ relation: rel, key: rel.model.quoted_table_name })
      new(root_node).relation
    end

    def relation
      @relation ||= render_ast
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

    define_lookup :present? do |p, node|
      last_access_node = node.parent
      parent_node = last_access_node.parent

      parent_node.child!('filter', {
        raw: "#{!p ? 'NOT' : ''} #{sqlize_path(parent_node)} ? '#{last_access_node[:key]}'"
      })

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
            where t.x IN (#{var_for(p, as: nil)})
          )
        SQL
      else
        " && ARRAY[#{var_for(p, as: nil)}]"
      end
    end

    define_lookup :contains, "@>"
    define_lookup :contained_by, "<@"
    define_lookup :gt, ">"
    define_lookup :gte, ">="
    define_lookup :lt, "<"
    define_lookup :lte, "<="

    protected

    def render_ast(node = @root_node)
      @current_node = node

      relation_node = node.traverse_up do |n|
        throw :found if n[:relation]
      end

      model = relation_node[:relation].model

      case node.type
      when 'root'
        ast_render_children(node)
      when 'access'
        key = node[:key]
        assocs_by_name = model.reflect_on_all_associations.index_by(&:name)
        assoc = assocs_by_name[key.to_sym]

        if assoc
          node[:relation] ||= assoc.klass.all
          ast_render_children(node)
          relation_node[:relation] = relation_node[:relation].where_exists(key, node[:relation])
        else
          ast_render_children(node)
        end
      when 'filter'
        clause = nil
        if node[:raw]
          clause = node[:raw]
        else
          clause = catch :full_clause do
            x = parse_lookup(node)
            throw :full_clause, nil unless x.present?
            "#{sqlize_path(node)}#{x}"
          end
        end

        if clause.present?
          keys = clause.scan(/:(\w+)/).map(&:first).map(&:to_sym)
          bindings = keys.index_with { |k| @injected_vars[k] }
          relation_node[:relation] = relation_node[:relation].where(clause, **bindings)
        end
      end

      relation_node[:relation]
    end

    def ast_render_children(ast, only: nil, except: nil)
      ast.iterate_children do |child|
        next if only && !only.include?(child.type)
        next if except && except.include?(child.type)
        render_ast(child)
      end
    end

    def var_for(value, as = :context)
      return value if value.is_a?(Arel::Nodes::SqlLiteral)

      if as == :context
        if extract_path(@current_node).length > 2
          as = :jsonb
        else
          as = nil
        end
      end

      case as
      when *JSON_TYPES
        value = Arel.sql(ActiveRecord::Base.connection.quote(value.to_json))
      end

      ":#{super(value)}"
    end

    def sqlize_path(path)
      path = extract_path(path) if path.is_a?(ASTNode)

      bits = []
      path.each_with_index.map do |k, i|
        if i >= 2
          bits << "->'#{k}'"
        elsif i == 1
          bits << ".#{k}"
        else
          bits << k
        end
      end
      bits.join
    end

    def extract_path(node)
      path = []
      node.traverse_up do |n|
        path.unshift(n[:key]) if n.type == 'access' || n.type == 'root'
        throw :found if n[:relation]
      end
      path
    end
  end
end
