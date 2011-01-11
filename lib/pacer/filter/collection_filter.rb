module Pacer
  module Routes
    module Base
      def except(excluded)
        if excluded.is_a? Symbol
          chain_route :back => self, :filter => :property, :block => proc { |v| v.vars[excluded] != v }
        else
          chain_route(:back => self, :filter => :collection, :except => excluded)
        end
      end

      def only(included)
        if included.is_a? Symbol
          chain_route :back => self, :filter => :property, :block => proc { |v| v.vars[included] == v }
        else
          chain_route(:back => self, :filter => :collection, :only => included)
        end
      end
    end
  end

  module Filter
    module CollectionFilter
      def self.triggers
        [:except, :only]
      end

      def except=(collection)
        self.collection = collection
        @comparison = Pacer::Pipes::ComparisonFilterPipe::Filter::EQUAL
      end

      def only=(collection)
        self.collection = collection
        @comparison = Pacer::Pipes::ComparisonFilterPipe::Filter::NOT_EQUAL
      end

      protected

      def collection=(collection)
        collection = [collection] unless collection.is_a? Enumerable
        @ids = element_id_hashset(collection)
        @objects = collection.to_hashset unless @ids
      end

      def element_id_hashset(collection)
        if collection.respond_to? :element_ids
          collection.element_ids.to_hashset
        else
          collection.to_hashset(:element_id) rescue nil
        end
      end

      def attach_pipe(end_pipe)
        if @ids
          pipe = Pacer::Pipes::IdCollectionFilterPipe.new(@ids, @comparison)
        else
          pipe = Pacer::Pipes::CollectionFilterPipe.new(@objects, @comparison)
        end
        pipe.set_starts(end_pipe)
        pipe
      end

      def collection_count
        @collection.count
      end

      def inspect_class_name
        if @comparison == Pacer::Pipes::ComparisonFilterPipe::Filter::EQUAL
          'Except'
        else
          'Only'
        end
      end

      def inspect_string
        c = (@ids || @objects)
        "#{ inspect_class_name }(#{c.count} elements)"
      end
    end
  end
end
