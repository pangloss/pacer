module Pacer
  import com.tinkerpop.blueprints.TransactionalGraph

  module GraphTransactionsMixin
    def in_transaction?
      threadlocal_graph_info.fetch(:tx_depth, 0) > 0
    end

    def in_read_transaction?
      threadlocal_graph_info.fetch(:read_tx_depth, 0) > 0
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
      tx_depth = nil
      begin
        if Pacer.verbose == :very
          tx_depth = threadlocal_graph_info[:dx_depth]
          puts "--#{self.class.name} transaction #{ tx_depth } --> "
          puts caller[0,3]
        end
        r = yield commit, rollback
        commit.call(false)
        r
      rescue Exception => e
        rollback.call e.message
        raise
      ensure
        puts "--#{self.class.name} #{ tx_depth } <-- " if Pacer.verbose == :very
        finish_transaction!
      end
    end

    alias tx transaction

    def read_transaction
      tgi = threadlocal_graph_info
      read_tx_depth = tgi[:read_tx_depth] ||= 0
      tgi[:read_tx_depth] += 1
      # Blueprints auto-starts the transaction
      reopen_read_transaction
      yield
    ensure
      rtd = tgi[:read_tx_depth] -= 1
      if rtd == 0 and tgi[:tx_depth] == 0 and blueprints_graph.is_a? TransactionalGraph
        # rollback after the bottom read transaction (no changes outside a real transaction block should have been possible)
        blueprints_graph.rollback
      end
    end

    def reopen_read_transaction
      # override this implementation-specific hook if needed (see pacer-neo4j)
    end

    # Set this to true if you don't want to use transactions.
    #
    # By default, transactions are enabled.
    #
    # Note that this does not prevent blueprints implicit transactions from
    # being created.
    attr_accessor :disable_transactions

    # This is to work around the bad transaction design in Blueprints.
    # Blueprints will always automatically start a transaction for you that it
    # doesn't commits automatically and which you can not check the status of
    # in any way. To deal with that, Pacer will (by default) commit implicit
    # transactions before an explicit transaction is created. You can change
    # that behavior by setting one of :commit, :rollback or :ignore. Ignore
    # effectively folds changes from before the transaction into the current
    # transaction.
    attr_accessor :implicit_transaction

    def close_implicit_transaction
      case implicit_transaction
      when nil, :commit
        commit_implicit_transaction
      when :rollback
        rollback_implicit_transaction
      else
        fail Pacer::ClientError, "invalid value for #implicit_transaction: #{ implicit_transaction.inspect }"
      end
    end

    def rollback_implicit_transaction
      blueprints_graph.rollback
    end

    def commit_implicit_transaction
      blueprints_graph.commit
    end

    attr_reader :on_commit_block

    def on_commit(&block)
      return unless block
      @on_commit_block = block
    end

  private

    def threadlocal_graph_info
      graphs = Thread.current[:graphs] ||= {}
      graphs[blueprints_graph.object_id] ||= {}
    end

    # NOTE pacer-orient reimplements this
    def start_transaction!(opts)
      tgi = threadlocal_graph_info
      tx_depth = tgi[:tx_depth] ||= 0
      tgi[:tx_depth] += 1
      begin
        if (not disable_transactions) and blueprints_graph.is_a? TransactionalGraph
          if tx_depth == 0
            close_implicit_transaction
            base_tx_finalizers
          elsif opts[:nesting] == true
            nested_tx_finalizers
          else
            fail NestedTransactionError, "To use nested transactions, use nesting: true"
          end
        else
          if tx_depth == 0
            mock_base_tx_finalizers
          else
            mock_nested_tx_finalizers
          end
        end
      rescue Exception
        tgi[:tx_depth] -= 1
        raise
      end
    end

    # NOTE pacer-orient reimplements this
    def finish_transaction!
      threadlocal_graph_info[:tx_depth] -= 1 rescue nil
    end

    # NOTE pacer-orient reimplements this
    # A better name for this would be "create_real_transaction", vs. the other finalizers which are all mock transactions in the default
    # implementation.
    def base_tx_finalizers
      tx_id = threadlocal_graph_info[:tx_id] = rand
      commit = ->(reopen = true) do
        if tx_id != threadlocal_graph_info[:tx_id]
          fail InternalError, 'Can not commit transaction outside its original block'
        end
        puts "transaction committed" if Pacer.verbose == :very
        blueprints_graph.commit
        # reopen arg is ignored for graphs that automatically open their tx.
        reopen_read_transaction
        on_commit_block.call if on_commit_block
      end
      rollback = ->(message = nil) do
        puts ["transaction rolled back", message].compact.join(': ') if Pacer.verbose == :very
        blueprints_graph.rollback
        reopen_read_transaction
      end
      [commit, rollback]
    end

    def nested_tx_finalizers
      commit = ->(reopen = true) do
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
      commit = ->(reopen = true) do
        puts "mock transaction committed" if Pacer.verbose == :very
        on_commit_block.call if on_commit_block
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
      commit = ->(reopen = true) do
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
