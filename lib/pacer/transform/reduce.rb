module Pacer
  module Routes
    module RouteOperations
      def reducer(opts = {}, &block)
        chain_route({transform: :reduce, reduce: block}.merge(opts))
      end
    end
  end

  module Transform
    module Reduce
      # The goal is to break down the xml stream from being a black
      # box iterator to doing the job in a few steps:

      def help(section = nil)
        case section
        when nil
          puts <<HELP

HELP
        when :example
          puts <<HELP
This example usage is from pacer-xml plugin v0.2. I transform a raw
stream of lines from a 79MB file that contains > 4000 concatinated xml
documents averaging 600 lines each. to a stream of imported nodes:

First, a little setup: create a graph, open the file and make a route of
its lines

  graph = Pacer.tg
  f = File.open '/tmp/ipgb20120103.xml'
  lines = f.each_line.to_route(element_type: :string).route

Create a simple reducer that delimits sections when it hits a DTD tag
and when it gets to the end of the file (that's the s.nil?). and reduces
the stream by pushing each section's lines into an array. When a section
is entered, the initial value is provided by the return value of the
enter block.

  reducer = lines.reducer(element_type: :array).route
  reducer.enter  { |s|        []     if s =~ /<\?xml/ }
  reducer.reduce { |s, lines| lines << s              }
  reducer.leave  { |s, lines| s.nil? or s =~ /<\?xml/ }

Now we're back in the territory of fairly vanilla routes. We join each
section, use the pacer-xml gem's StringRoute#xml method to parse the XML
with Nokogiri and then its XmlRoute#import method to turn those XML
nodes into graph elements.

  vertex = reducer.map(element_type: :string, &:join).xml.limit(1).import(graph).first

  graph           #=> #<PacerGraph tinkergraph[vertices:88 edges:90]
  vertex          #=> #<V[0] us-patent-grant>

We can see that we've now got a graph with 88 vertices and 90 edges.

HELP
        end
      end

      attr_writer :enter, :reduce, :leave

      def enter(&block)
        if block
          @enter = block
        end
        self
      end

      def reduce(&block)
        if block
          @reduce = block
        end
        self
      end

      def leave(same_as = nil, &block)
        if same_as == :enter
          @leave = @enter
        elsif block
          @leave = block
        end
        self
      end

      def attach_pipe(end_pipe)
        if @enter and @reduce and @leave
          pipe = ReducerPipe.new self, @enter, @reduce, @leave
          pipe.setStarts end_pipe
          pipe
        else
          fail Pacer::ClientError, 'enter, reduce, and leave must all be specified for reducers'
        end
      end

      class ReducerPipe < Pacer::Pipes::RubyPipe
        attr_reader :enter, :reduce, :leave, :change_value
        attr_accessor :changed_value, :value_changed
        attr_accessor :next_value

        def initialize(back, enter, reduce, leave)
          super()
          @change_value = proc do |new_value|
            self.changed_value = new_value
            self.value_changed = true
          end
          @enter = Pacer::Wrappers::WrappingPipeFunction.new back, enter
          @reduce = Pacer::Wrappers::WrappingPipeFunction.new back, reduce
          @leave = Pacer::Wrappers::WrappingPipeFunction.new back, leave
          @next_value = nil
        end

        def processNextStart
          if next_value
            collecting = true
            value = next_value
            self.next_value = nil
          else
            collecting = false
          end
          leaving = false
          final_value = nil
          while raw_element = starts.next
            if collecting
              if leave.call_with_args(raw_element, value, change_value)
                leaving = true
                return_value = final_value(value)
                collecting = false
              else
                value = reduce.call_with_args(raw_element, value)
              end
            end
            if not collecting
              value = enter.call raw_element
              if value
                collecting = true
                value = reduce.call_with_args(raw_element, value)
              end
            end
            if leaving
              self.next_value = value if collecting
              return return_value
            end
          end
        rescue Pacer::EmptyPipe, java.util.NoSuchElementException
          if collecting and leave.call_with_args(nil, value, change_value)
            return final_value(value)
          end
          raise EmptyPipe.instance
        end

        private

        def final_value(value)
          if value_changed
            self.value_changed = false
            value = changed_value
            self.changed_value = nil
          end
          value
        end
      end
    end
  end
end
