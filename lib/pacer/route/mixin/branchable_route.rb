module Pacer::Routes
  module BranchableRoute
    # Branch the route on a path defined within the given block. Call this
    # method multiple times in a row to branch the route over different paths
    # before merging back.
    def branch(&block)
      br = BranchedRoute.new(self, block)
      if br.branch_count == 0
        self
      else
        br
      end
    end
  end
end
