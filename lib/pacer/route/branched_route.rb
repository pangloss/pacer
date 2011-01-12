module Pacer::Routes
  class BranchedRoute
    include Pacer::Core::Route
    include RouteOperations
    include Pacer::Core::Graph::MixedRoute

    def initialize(back, block = nil)
      @back = back
      @branches = []
      @split_pipe = Pacer::Pipes::CopySplitPipe
      @merge_pipe = Pacer::Pipes::RobinMergePipe
      branch &block if block
    end

    def branch(&block)
      if @back.is_a? Pacer::Graph
        branch_start = @back
      else
        branch_start = Pacer::Route.new(:back => @back, :filter => :empty)
      end
      branch = yield(branch_start)
      if branch.equal? branch_start
        # TODO: allow chain_route to work this way
        # branch = branch.chain_route :type => :identity
        # @branches << [branch.route, true] if branch
      elsif branch
        @branches << [branch.route, true]
      end
      self
    end

    def source_branch(&block)
      branch = yield
      @branches << [branch.route, false] if branch
      self
    end

    def branch_count
      @branches.count
    end

    def root?
      false
    end

    def merge
      chain_route
    end

    def robin_split
      split_pipe(Pacer::Pipes::RobinSplitPipe)
    end

    def exhaustive
      merge_pipe(Pacer::Pipes::ExhaustiveMergePipe)
    end

    def merge_pipe(pipe_class, &block)
      @merge_pipe = pipe_class
      @configure_merge_pipe = block
      self
    end

    def merge_pipe?
      @merge_pipe
    end

    def split_pipe(pipe_class, &block)
      @split_pipe = pipe_class
      @configure_split_pipe = block
      self
    end

    def split_pipe?
      @split_pipe
    end

    protected

    def build_pipeline
      first_pipe, source_pipe = pipe_source
      split_pipe = @split_pipe.new @branches.count
      split_pipe.set_starts source_pipe if source_pipe
      if split_pipe.respond_to? :route=
        split_pipe.route = self
      end
      @configure_split_pipe.call(split_pipe) if @configure_split_pipe
      split_idx = 0
      branch_start_pipes = []
      branch_pipes = @branches.map do |branch, uses_split_pipe|
        start_pipe, end_pipe = branch.send(:build_pipeline)
        branch_start_pipes << start_pipe
        if uses_split_pipe
          start_pipe.set_starts(split_pipe.get_split(split_idx))
          split_idx += 1
        end
        end_pipe
      end
      merge_pipe = @merge_pipe.new
      merge_pipe.set_starts(branch_pipes)
      @configure_merge_pipe.call(merge_pipe) if @configure_merge_pipe
      Pacer.debug_pipes << (['Split', first_pipe, split_pipe, branch_start_pipes, merge_pipe]) if Pacer.debug_pipes
      [first_pipe || split_pipe || merge_pipe, merge_pipe]
    end

    def inspect_class_name
      "#{super} { #{ @branches.map { |e, _| e.inspect }.join(' | ') } }"
    end
  end
end
