module Pacer
  import com.tinkerpop.blueprints.TransactionalGraph

  module GraphTransactionsMixin
    def in_transaction?
      threadlocal_graph_info.fetch(:tx_depth, 0) > 0
    end

    # Basic usage:
    #
    # graph.transaction do |commit, rollback|
    #   if problem?
    #     rollback.call    # rolls back the most recent chunk
    #   elsif chunk_transaction?
    #     commit.call      # can be called multiple times, breaking the tx into chunks
    #   elsif error?
    #     raise "bad news" # most recent chunk is rolled back automatically
    #   end
    #   # will automatically commit
    # end
    #
    # Note that rollback may raise a Pacer::NestedTransactionRollback exception, which
    # if uncaught will cause the top level transaction to rollback.
    #
    # It might be a good idea to be able to specify a strategy for nested commits & rollbacks
    # other than the one I've done here. I don't have any use cases I need it for but if
    # anyone does I'd like to discuss it and have some ideas how to implement them.
    #
    # Also considering a 3rd callback that could be used to get info about the
    # current transaction stack like depth, number of commits/rollbacks, possibly the number of
    # mutations it wraps and even some event registration stuff could be made available.
    #
    # opts:
    #   nesting: true  -- allow mock nested transactions
    #   nesting: false -- (default) raise an exception instead of starting a nested transaction
    def transaction(opts = {})
      commit, rollback = start_transaction! opts
      begin
        r = yield commit, rollback
        commit.call
        r
      rescue Exception => e
        rollback.call e.message
        raise
      ensure
        finish_transaction!
      end
    end

  private

    def threadlocal_graph_info
      graphs = Thread.current[:graphs] ||= {}
      graphs[blueprints_graph.object_id] ||= {}
    end

    def start_transaction!(opts)
      tgi = threadlocal_graph_info
      tx_depth = tgi[:tx_depth] ||= 0
      tgi[:tx_depth] += 1
      if blueprints_graph.is_a? TransactionalGraph
        if tx_depth == 0
          base_tx_finalizers
        elsif opts[:nesting] == true
          nested_tx_finalizers
        else
          fail NestedTransactionError
        end
      else
        if tx_depth == 0
          mock_base_tx_finalizers
        else
          mock_nested_tx_finalizers
        end
      end
    end

    def finish_transaction!
      threadlocal_graph_info[:tx_depth] -= 1 rescue nil
    end

    def base_tx_finalizers
      tx_id = threadlocal_graph_info[:tx_id] = rand
      commit = -> do
        if tx_id != threadlocal_graph_info[:tx_id]
          fail InternalError
        end
        puts "transaction committed" if Pacer.verbose == :very
        blueprints_graph.stopTransaction TransactionalGraph::Conclusion::SUCCESS
      end
      rollback = ->(message = nil) do
        puts ["transaction rolled back", message].compact.join(': ') if Pacer.verbose == :very
        blueprints_graph.stopTransaction TransactionalGraph::Conclusion::FAILURE
      end
      [commit, rollback]
    end

    def nested_tx_finalizers
      commit = -> do
        puts "nested transaction committed (noop)" if Pacer.verbose == :very
      end
      rollback = ->(message = 'Transaction Rolled Back') do
        puts "nested transaction rolled back: #{ message }" if Pacer.verbose == :very
        unless $!
          message ||= "Can not rollback a nested transaction"
          fail NestedTransactionRollback, message
        end
      end
      [commit, rollback]
    end

    def mock_base_tx_finalizers
      commit = -> do
        puts "mock transaction committed" if Pacer.verbose == :very
      end
      rollback = ->(message = nil) do
        puts ["mock transaction rolled back", message].compact.join(': ') if Pacer.verbose == :very
        unless $!
          message ||= "Can not rollback a mock transaction"
          fail MockTransactionRollback, message
        end
      end
      [commit, rollback]
    end

    def mock_nested_tx_finalizers
      commit = -> do
        puts "nested transaction committed (noop)" if Pacer.verbose == :very
      end
      rollback = ->(message = nil) do
        puts "nested transaction rolled back: #{ message }" if Pacer.verbose == :very
        unless $!
          message ||= "Can not rollback a mock or nested transaction"
          fail NestedMockTransactionRollback, message
        end
      end
      [commit, rollback]
    end
  end
end
