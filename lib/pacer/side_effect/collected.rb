module Pacer
  module Core
    module Route
      def collect_with(multigraph)
        vars[:multigraph] = multigraph
      end

      def collect_as(name, opts = {})
        process do |element|
          g = vars[:multigraph] ||= Pacer::MultiGraph.new
          v = vars[name] = g.create_vertex
          v[name] = element
          within = opts[:within]
          if within
            within_v = vars[within]
            g.create_edge nil, v, within_v, :within
          end
        end
      end

      def add_to(collection_name, name = nil)
        process do |element|
          v = vars[collection_name]
          if name
            existing = v[name]
            if existing
              existing << element
            else
              v[name] = [element]
            end
          end
          if block_given?
            yield v, element
          end
        end
      end

      def map_to(collection_name, name)
        process do |element|
          v = vars[collection_name]
          existing = v[name]
          if block_given?
            mapped = yield element, v
          else
            mapped = element
          end
          if existing
            existing << mapped
          else
            v[name] = [mapped]
          end
        end
      end

      def reduce_to(collection_name, name, starting_value)
        process do |element|
          v = vars[collection_name]
          total = v[name]
          if total
            v[name] = yield total, element
          else
            v[name] = yield starting_value, element
          end
        end
      end

      def execute!
        p = pipe
        while p.hasNext
          p.next
        end
        self.route
      end

      def collected(name = nil)
        # TODO: VarSideEffectPipe
        if name
          map(graph: vars[:multigraph], element_type: :vertex) { vars[name] }
        else
          execute!.vars[:multigraph]
        end
      end
    end
  end
end
