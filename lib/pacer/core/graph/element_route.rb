module Pacer::Core::Graph

  # Basic methods for routes shared between all route types that emit
  # routes: {VerticesRoute}, {EdgesRoute} and {MixedRoute}
  module ElementRoute
    # Attach a filter to the current route.
    #
    # @param [Array<Hash, extension>, Hash, extension] filter see {Pacer::Route#property_filter}
    # @yield [ElementWrapper] filter proc, see {Pacer::Route#property_filter}
    # @return [ElementRoute] the same type and extensions as the source route.
    def filter(*filters, &block)
      Pacer::Route.property_filter(self, filters, block)
    end

    # v is undefined for edge routes.
    # @see VerticesRoute
    # @see GraphRoute
    def v(*filters)
      raise Pacer::UnsupportedOperation, "Can't get vertices for this route type."
    end

    # Undefined for vertex routes.
    # @see EdgesRoute
    # @see GraphRoute
    def e(*filters, &block)
      raise Pacer::UnsupportedOperation, "Can't get edges for this route type."
    end

    # Attach a transform that emits the properties of the elements
    # rather than the elements themselves.
    # @return [Core::Route]
    def properties
      map(element_type: :hash) { |v| v.properties }
    end

    def raw_property_maps
      chain_route(:element_type => :object,
                  :pipe_class => Pacer::Pipes::PropertyMapPipe)
    end

    # Create a new TinkerGraph based on the paths of all matching elements.
    #
    # @return [TinkerGraph] the subgraph
    def subgraph(graph = nil, opts = {})
      graph, opts = [nil, graph] if graph.is_a? Hash
      paths.subgraph graph, opts
    end

    # Delete all matching elements.
    def delete!
      count = 0
      uniq.bulk_job { |e| count += 1; e.delete! }
      count
    end

    # Stores the result of the current route in a new route so it will not need
    # to be recalculated.
    # @return [ElementRoute] with the same type and extensions as the
    #   source route
    def result(name = nil)
      element_ids.to_a.id_to_element_route(:based_on => self, :name => name)
    end

    # Accepts a string or symbol to return an array of matching properties, or
    # an integer to return the element at the given offset, or a range to
    # return all elements between the offsets within the range.
    # @overload [](prop)
    #   @param [String, Symbol] prop map each element to a single property
    #   @return [Core::Route]
    # @overload [](properties)
    #   @param [Array<String, Symbol>] properties map each element to a set of properties
    #   @return [Core::Route]
    # @overload [](offset)
    #   @param [Fixnum] offset narrow the result to a single element at the given position in the results
    #   @return [ElementRoute] with the same type and extensions as the source route
    # @overload [](range)
    #   @param [Range] range narrow the result to a subset of elements in positions corresponding to the range
    #   @return [ElementRoute] with the same type and extensions as the source route
    def [](prop_or_subset)
      case prop_or_subset
      when String, Symbol
        typed_property(:object, prop_or_subset)
      when Fixnum
        range(prop_or_subset, prop_or_subset)
      when Range
        range(prop_or_subset.begin, prop_or_subset.end)
      when Array
        if prop_or_subset.all? { |i| i.is_a? String or i.is_a? Symbol }
          map(element_type: :array) do |element|
            element[prop_or_subset]
          end
        end
      end
    end

    def typed_property(element_type, name)
      route = chain_route(:element_type => :object,
                          :pipe_class => Pacer::Pipes::PropertyPipe,
                          :pipe_args => [name.to_s],
                          :lookahead_replacement => proc { |r| r.back.property?(name) })
      route.map(route_name: 'decode', remove_from_lookahead: true, element_type: element_type) do |v|
        graph.decode_property(v)
      end
    end

    # Map each element to a property but filter out elements that do not
    # have the given property.
    # @param [#to_s] name the property name
    # @return [Core::Route]
    def property?(name)
      chain_route(:element_type => :object,
                  :pipe_class => Pacer::Pipes::PropertyPipe,
                  :pipe_args => [name.to_s, false])
    end

    # Attach a route to the element id for each element emitted by the
    # route.
    #
    # @return [Core::Route]
    def element_ids
      chain_route :element_type => :object, :pipe_class => Pacer::Pipes::IdPipe
    end

    def clone_into(target_graph, opts = {})
      bulk_job(nil, target_graph) do |element|
        element.clone_into(target_graph, opts)
      end
    end

    def copy_into(target_graph, opts = {})
      bulk_job(nil, target_graph) { |element| element.copy_into(target_graph, opts) }
    end

    def build_index(index, index_key = nil, property = nil, create = true)
      index_name = index
      unless index.is_a? com.tinkerpop.blueprints.Index
        index = graph.index index.to_s
      end
      sample_element = first
      unless index
        if sample_element
          if create
            index = graph.index index_name, graph.element_type(sample_element), create: true
          else
            raise "No index found for #{ index } on #{ graph }" unless index
          end
        else
          return nil
        end
      end
      index_key ||= index.name
      property ||= index_key
      if block_given?
        bulk_job do |element|
          value = yield(element)
          index.put(index_key, value, element.element) if value
        end
      else
        bulk_job do |element|
          value = element[property]
          index.put(index_key, value, element.element) if value
        end
      end
      index
    end

    protected

    def configure_iterator(iter, g = nil)
      pipe = Pacer::Pipes::WrappingPipe.new((g || graph), element_type, extensions)
      pipe.wrapper = wrapper if wrapper
      pipe.setStarts iter
      pipe
    end
  end
end
