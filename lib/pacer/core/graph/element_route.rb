module Pacer::Core::Graph

  module ElementRoute

    def filter(*filters, &block)
      Pacer::Route.property_filter(self, filters, block)
    end

    # v is undefined for edge routes.
    def v(*filters)
      raise Pacer::UnsupportedOperation, "Can't get vertices for this route type."
    end

    # Undefined for vertex routes.
    def e(*filters, &block)
      raise Pacer::UnsupportedOperation, "Can't get edges for this route type."
    end

    def properties
      map { |v| v.properties }
    end

    # Create a new TinkerGraph based on the paths of all matching elements.
    def subgraph
      paths.subgraph
    end

    # Delete all matching elements.
    def delete!
      uniq.bulk_job { |e| e.delete! }
    end

    # Stores the result of the current route in a new route so it will not need
    # to be recalculated.
    def result(name = nil)
      element_ids.to_a.id_to_element_route(:based_on => self, :name => name)
    end

    # Accepts a string or symbol to return an array of matching properties, or
    # an integer to return the element at the given offset, or a range to
    # return all elements between the offsets within the range.
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
            prop_or_subset.collect { |i| element.get_property(i.to_s) }
          end
        end
      end
    end

    def property?(name)
      chain_route(:element_type => :object,
                  :pipe_class => Pacer::Pipes::PropertyPipe,
                  :pipe_args => [name.to_s, true])
    end

    # Returns an array of element ids.
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
      unless index.is_a? com.tinkerpop.blueprints.pgm.Index
        index = graph.indices.find { |i| i.index_name == index.to_s }
      end
      sample_element = first
      unless index
        if sample_element
          if create
            index = graph.createManualIndex index_name, graph.element_type(sample_element)
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

  end
end
