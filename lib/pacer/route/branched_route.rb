module Pacer::Routes
  class BranchedRoute
    include Base
    include RouteOperations
    include MixedRouteModule

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
        branch_start = FilterRoute.new(:back => @back, :filter => :empty)
      end
      branch = yield(branch_start)
      @branches << branch.route if branch and branch != branch_start
      self
    end

    def branch_count
      @branches.count
    end

    def root?
      false
    end

    def merge
      MixedElementsRoute.new(self)
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
      if source_pipe.is_a? Pacer::Graph
        branch_pipes = @branches.map { |branch| branch.send :iterator }
      else
        split_pipe = @split_pipe.new @branches.count
        split_pipe.set_starts source_pipe if source_pipe
        if split_pipe.respond_to? :route=
          split_pipe.route = self
        end
        @configure_split_pipe.call(split_pipe) if @configure_split_pipe
        idx = 0
        branch_pipes = @branches.map do |branch|
          start_pipe, end_pipe = branch.send(:build_pipeline)
          start_pipe.set_starts(split_pipe.get_split(idx))
          idx += 1
          end_pipe
        end
      end
      merge_pipe = @merge_pipe.new
      merge_pipe.set_starts(branch_pipes)
      @configure_merge_pipe.call(merge_pipe) if @configure_merge_pipe
      [first_pipe || split_pipe || merge_pipe, merge_pipe]
    end

    def inspect_class_name
      "#{super} { #{ @branches.map { |e| e.inspect }.join(' | ') } }"
    end

    def route_class
      MixedElementsRoute
    end
  end
end
