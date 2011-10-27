module Pacer
  module Core
    module Route
      def branch(args = {}, &block)
        route = chain_route({transform: :branch, element_type: :mixed}.merge args)
        route.branch &block if block
        route
      end
    end
  end

  module ElementMixin
    def branch(args = {}, &block)
      route = chain_route({transform: :branch, element_type: :mixed}.merge args)
      route.branch &block if block
      route
    end
  end

  module Transform
    module Branch
      import com.tinkerpop.pipes.branch.FairMergePipe
      import com.tinkerpop.pipes.branch.ExhaustMergePipe
      import com.tinkerpop.pipes.branch.CopySplitPipe

      attr_reader :split_pipe, :merge_pipe
      attr_reader :branches

      def merge_pipe=(name)
        case name
        when :fair
          @merge_pipe = FairMergePipe
        when :exhaust, :exhaustive
          @merge_pipe = ExhaustMergePipe
        when Module
          @merge_pipe = name
        else
          raise "Unknown merge pipe #{ name.inspect }"
        end
      end

      def split_pipe=(name)
        case name
        when :copy
          @split_pipe = CopySplitPipe
        when Module
          @split_pipe = name
        else
          raise "Unknown split pipe #{ name.inspect }"
        end
      end

      def branch(&block)
        route = Pacer::Route.block_branch(back, block)
        branches << [route, block.arity == 1]
        element_types = branches.map { |r, _| r.element_type }.uniq
       #if element_types.length == 1
       #  puts element_types.first
       #elsif element_types.include? Object
       #  puts Object
       #else
       #  puts :mixed
       #end
        self
      end

      def merge
        chain_route(pipe_class: Pacer::Pipes::IdentityPipe)
      end

      def exhaustive
        @merge_pipe = ExhaustMergePipe
        self
      end

      def fair
        @merge_pipe = FairMergePipe
        self
      end

      protected

      def after_initialize
        @branches = []
        @merge_pipe = FairMergePipe
        @split_pipe = CopySplitPipe
      end

      def attach_pipe(source_pipe)
        first_branch_pipe = nil
        branch_pipes = []
        all_branch_pipes = []
        branches.map do |route, use_split|
          pipe = Pacer::Route.pipeline(route)
          all_branch_pipes << pipe
          if use_split
            if first_branch_pipe
              branch_pipes << pipe
            else
              first_branch_pipe = pipe
            end
          end
        end
        if branch_pipes.any?
          split = split_pipe.new branch_pipes
          first_branch_pipe.setStarts split
          split.set_starts source_pipe if source_pipe
        elsif first_branch_pipe
          first_branch_pipe.setStarts source_pipe if source_pipe
        end
        if all_branch_pipes.any?
          merge_pipe.new all_branch_pipes
        else
          source_pipe
        end
      end

      def inspect_string
        "#{inspect_class_name} { #{ branches.collect { |r, _| r.inspect }.join(' | ') } }"
      end
    end
  end
end
