module Pacer
  module Routes
    module RouteOperations
      def reducer(opts = {})
        chain_route({:transform => :reduce, :extensions => []}.merge(opts))
      end
    end
  end

  module Transform
    module Reduce
      # The goal is to break down the xml stream from being a black
      # box iterator to doing the job in a few steps:

      def idea(io)
        lines = Pacer.io_lines(io) # t: :string
        blocks = lines.reducer(t: :array)
        blocks.enter do |line|
          [] if line =~ /<\?xml/
        end
        blocks.reduce do |line, lines|
          lines << line
          lines
        end
        blocks.leave do |line, lines, change_value|
          line.nil? or line =~ /<\?xml/
        end
        xml_strings = blocks.map(t: :xml, &:join)
        xml_strings.xml
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
