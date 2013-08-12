module Pacer
  module Core
    module Route
      def branch(&block)
        route = chain_route transform: ::Pacer::Transform::Branch
        route.add_block! &block
      end
    end
  end

  module Transform
    module Branch
      import com.tinkerpop.pipes.branch.CopySplitPipe;
      import com.tinkerpop.pipes.branch.ExhaustMergePipe
      import com.tinkerpop.pipes.branch.FairMergePipe

      attr_accessor :branches, :split_pipe_class, :merge_pipe_class

      def after_initialize
        super
        self.branches ||= []
        self.split_pipe_class ||= CopySplitPipe
        self.merge_pipe_class ||= FairMergePipe
      end

      def clone
        back.chain_route(transform: Branch,
                         branches: branches.clone,
                         extensions: extensions.clone,
                         split_pipe_class: split_pipe_class,
                         merge_pipe_class: merge_pipe_class)
      end

      def branch(&block)
        route = clone
        route.add_block! &block
      end

      def merge
        route = clone
        route.merge_pipe_class = FairMergePipe
        route
      end

      def merge_exhaustive
        route = clone
        route.merge_pipe_class = ExhaustMergePipe
        route
      end

      def add_block!(&block)
        branch = block.call(Pacer::Route.empty(back))
        branches.push branch
        exts = branches.
          map { |b| b.extensions }.
          map { |a| a ? a.to_set : Set[] }.
          reduce { |r, e| r.intersection(e) }
        config[:extensions] = exts.to_a
        self
      end

      def attach_pipe(end_pipe)
        branch_pipes = branches.map { |b| Pacer::Route.pipeline(b) }
        split = split_pipe_class.new branch_pipes
        split.setStarts end_pipe
        merge = merge_pipe_class.new branch_pipes
        merge.setStarts split
        merge
      end
    end
  end
end

