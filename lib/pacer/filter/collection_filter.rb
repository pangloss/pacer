module Pacer
  module Core
    module Route
      def except(excluded)
        if excluded.is_a? Symbol
          chain_route :filter => :collection, :except_var => excluded
        else
          chain_route :filter => :collection, :except => excluded
        end
      end

      def -(other)
        chain_route :filter => :collection, :except => other
      end

      def only(included)
        if included.is_a? Symbol
          chain_route :filter => :collection, :only_var => included
        else
          chain_route :filter => :collection, :only => included
        end
      end
    end
  end

  module Filter
    module CollectionFilter
      import java.util.HashSet

      include Pacer::Visitors::VisitsSection

      attr_reader :var, :comparison, :ids, :objects

      def except=(collection)
        self.collection = collection
        @comparison = Pacer::Pipes::NOT_CONTAINED_IN
      end

      def except_var=(var)
        @var = var
        self.section = var
        @comparison = Pacer::Pipes::NOT_CONTAINED_IN
      end

      def only=(collection)
        self.collection = collection
        @comparison = Pacer::Pipes::CONTAINED_IN
      end

      def only_var=(var)
        @var = var
        self.section = var
        @comparison = Pacer::Pipes::CONTAINED_IN
      end

      protected

      def collection=(collection)
        collection = [collection] unless collection.is_a? Enumerable
        @ids = nil
        if collection.is_a? HashSet
          @objects = collection
        elsif element_type != Object
          @ids = element_id_hashset(collection)
          @objects = collection.to_hashset unless ids
        else
          @objects = collection.to_hashset
        end
      end

      def element_id_hashset(collection)
        if collection.is_a? Pacer::Core::Graph::ElementRoute
          collection.element_ids.to_hashset
        else
          collection.to_hashset(:element_id) rescue nil
        end
      end

      def attach_pipe(end_pipe)
        if section_visitor_target
          element = section_visitor_target.new
          # Will cause section_visitor to call the #on_element and #reset methods.
          section_visitor.visitor = element
          pipe = Pacer::Pipes::CollectionFilterPipe.new(element, comparison)
        elsif ids
          pipe = Pacer::Pipes::IdCollectionFilterPipe.new(ids, comparison)
        else
          pipe = Pacer::Pipes::CollectionFilterPipe.new(objects, comparison)
        end
        pipe.set_starts(end_pipe) if end_pipe
        pipe
      end

      def collection_count
        @collection.count
      end

      def inspect_class_name
        if @comparison == Pacer::Pipes::NOT_CONTAINED_IN
          'Except'
        else
          'Only'
        end
      end

      def inspect_string
        if var
          "#{ inspect_class_name }(#{ var.inspect })"
        else
          c = (ids || objects)
          "#{ inspect_class_name }(#{c.count} elements)"
        end
      end
    end
  end
end
