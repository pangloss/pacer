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
      elsif @back.vertices_route?
        branch_start = VerticesIdentityRoute.new(self).route
      elsif @back.edges_route?
        branch_start = EdgesIdentityRoute.new(self).route
      elsif
        branch_start = MixedIdentityRoute.new(self).route
      end
      branch = yield(branch_start)
      @branches << [branch_start, branch.route] if branch and branch != branch_start
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

    def iterator
      if @back.is_a? Pacer::Graph
        add_branches_to_pipe(@back)
      else
        pipe = source
        add_branches_to_pipe(pipe)
      end
    end

    def add_branches_to_pipe(pipe)
      if pipe.is_a? Pacer::Graph
        pipes = @branches.map { |branch_start, branch_end| branch_end.send :iterator }
      else
        split_pipe = @split_pipe.new @branches.count
        split_pipe.set_starts pipe
        if split_pipe.respond_to? :route=
          split_pipe.route = self
        end
        @configure_split_pipe.call(pipe) if @configure_split_pipe
        idx = 0
        pipes = @branches.map do |branch_start, branch_end|
          branch_start.new_identity_pipe.set_starts(split_pipe.get_split(idx))
          idx += 1
          branch_end.iterator
        end
      end
      pipe = @merge_pipe.new
      pipe.set_starts(pipes)
      @configure_merge_pipe.call(pipe) if @configure_merge_pipe
      pipe
    end

    def inspect_class_name
      "#{super} { #{ @branches.map { |s, e| e.inspect }.join(' | ') } }"
    end

    def route_class
      MixedElementsRoute
    end
  end
end
