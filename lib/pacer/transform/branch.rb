module Pacer
  module Core
    module Route
      def branch(&block)
        route = chain_route transform: ::Pacer::Transform::Branch
        route.add_block! &block
      end

      def cond(where, &block)
        route = chain_route transform: ::Pacer::Transform::Branch
        route.add_cond! where, &block
      end
    end
  end

  class Wrappers::VertexWrapper
    def branch(&block)
      v.branch &block
    end
  end

  class Wrappers::EdgeWrapper
    def branch(&block)
      e.branch &block
    end
  end

  module Transform
    module Branch
      import com.tinkerpop.pipes.branch.CopySplitPipe
      import com.tinkerpop.pipes.branch.ExhaustMergePipe
      import com.tinkerpop.pipes.branch.FairMergePipe

      attr_accessor :branches, :split_pipe_class, :merge_pipe_class, :conds

      def after_initialize
        super
        self.branches ||= []
        self.conds ||= []
        self.split_pipe_class ||= CopySplitPipe
        self.merge_pipe_class ||= FairMergePipe
      end

      def clone(conf = {})
        back.chain_route({transform: Branch,
                          branches: branches.clone,
                          element_type: back.element_type,
                          conds: conds.clone,
                          extensions: extensions.clone,
                          split_pipe_class: split_pipe_class,
                          merge_pipe_class: merge_pipe_class
                         }.merge(conf))
      end

      def branch(&block)
        route = clone
        route.add_block! &block
      end

      def cond(where, &block)
        route = clone
        route.add_cond! where, &block
      end

      def otherwise(&block)
        where = "(#{ conds.compact.map { |c| "not (#{c})" }.join " and " })"
        cond where, &block
      end

      def merge
        route = clone
        route.merge_pipe_class = FairMergePipe
        route.chain_route transform: MergedBranch
      end

      def merge_exhaustive
        route = clone
        route.merge_pipe_class = ExhaustMergePipe
        route.chain_route transform: MergedBranch
      end

      def add_block!(&block)
        will_clone = false
        branch = block.call(Pacer::Route.empty(back))
        branches.push branch
        conf = {}

        exts = branches.
          map { |b| b.extensions }.
          map { |a| a ? a.to_set : Set[] }.
          reduce { |r, e| r.intersection(e) }
        if exts.to_a != config[:extensions]
          conf[:extensions] = exts.to_a
        end

        types = branches.map { |b| b.element_type }.to_set
        if types.length == 1
          type = types.first
        elsif types.difference([:vertex, :edge, :mixed]).empty?
          type = :mixed
        elsif types.difference([:path, :array]).empty?
          type = :array
        else
          type = :object
        end
        if type != element_type
          conf[:element_type] = type
        end
        if conf.empty?
          self
        else
          clone conf
        end
      end

      def add_cond!(where, &block)
        conds[branches.length] = where
        add_block! do |r|
          block.call r.where(where)
        end
      end

      def attach_pipe(end_pipe)
        branch_pipes = branches.map { |b| Pacer::Route.pipeline(b) }
        split = split_pipe_class.new branch_pipes
        merge = merge_pipe_class.new branch_pipes
        merge.setStarts split
        if end_pipe
          split.setStarts end_pipe
          merge
        else
          Pacer::Pipes::BlackboxPipeline.new split, merge
        end
      end
    end

    module MergedBranch
      # This just exists so that if I merge and then branch again,
      # the new branches will be against the merged source.
    end
  end
end

