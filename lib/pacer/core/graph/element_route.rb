module Pacer::Core::Graph

  # Basic methods for routes shared between all route types that emit
  # routes: {VerticesRoute}, {EdgesRoute} and {MixedRoute}
  module ElementRoute

    # Attach a filter to the current route.
    #
    # @param [Array<Hash, extension>, Hash, extension] filter see {Pacer::Route#property_filter}
    # @yield [ElementMixin(Extensions::BlockFilterElement)] filter proc, see {Pacer::Route#property_filter}
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
      map { |v| v.properties }
    end

    # Create a new TinkerGraph based on the paths of all matching elements.
    #
    # @return [TinkerGraph] the subgraph
    def subgraph opts = {}
      paths.subgraph nil, opts
    end

    # Delete all matching elements.
    def delete!
      uniq.bulk_job { |e| e.delete! }
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
        chain_route(:element_type => :object,
                    :pipe_class => Pacer::Pipes::PropertyPipe,
                    :pipe_args => [prop_or_subset.to_s])
      when Fixnum
        range(prop_or_subset, prop_or_subset)
      when Range
        range(prop_or_subset.begin, prop_or_subset.end)
      when Array
        if prop_or_subset.all? { |i| i.is_a? String or i.is_a? Symbol }
          map do |element|
            prop_or_subset.collect { |i| element.getProperty(i.to_s) }
          end
        end
      end
    end

    # Map each element to a property but filter out elements that do not
    # have the given property.
    # @param [#to_s] name the property name
    # @return [Core::Route]
    def property?(name)
      chain_route(:element_type => :object,
                  :pipe_class => Pacer::Pipes::PropertyPipe,
                  :pipe_args => [name.to_s, true])
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
      index_key ||= index.index_name
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

    # Determines which iterator mixin is applied to the iterator when #each is called
    def configure_iterator(iter)
      if wrapper
        iter.extend Pacer::Core::Route::IteratorWrapperMixin
        iter.wrapper = wrapper
        iter.extensions = @extensions if @extensions.any?
        iter.graph = graph
      elsif extensions and extensions.any?
        iter.extend Pacer::Core::Route::IteratorExtensionsMixin
        iter.extensions = extensions
        iter.graph = graph
      else
        iter.extend Pacer::Core::Route::IteratorMixin
        iter.graph = graph
      end
    end
  end
end
