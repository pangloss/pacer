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
      if @back.vertices_route?
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

    def exhaustive
      merge_pipe(Pacer::Pipes::ExhaustiveMergePipe)
    end

    def merge_pipe(pipe_class)
      @merge_pipe = pipe_class
      self
    end

    def merge_pipe?
      @merge_pipe
    end

    def split_pipe(pipe_class)
      @split_pipe = pipe_class
      self
    end

    def split_pipe?
      @split_pipe
    end

    protected

    def iterator
      pipe = source
      add_branches_to_pipe(pipe)
    end

    def add_branches_to_pipe(pipe)
      split_pipe = @split_pipe.new @branches.count
      split_pipe.set_starts pipe
      if split_pipe.respond_to? :route=
        split_pipe.route = self
      end
      idx = 0
      pipes = @branches.map do |branch_start, branch_end|
        branch_start.new_identity_pipe.set_starts(split_pipe.get_split(idx))
        idx += 1
        branch_end.iterator
      end
      pipe = @merge_pipe.new
      pipe.set_starts(pipes)
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
