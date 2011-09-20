module Pacer
  import com.tinkerpop.blueprints.pgm.TransactionalGraph

  # Collect a global set of graphs that are currently in a transaction.
  #
  # @return [Set] graphs with an open transaction
  def self.graphs_in_transaction
    @graphs = Set[] unless defined? @graphs
    @graphs
  end

  # Methods used internally to do 'managed transactions' which I define
  # as transactions that are started and committed automatically
  # internally, typically on operations that potentially touch a large
  # number of elements.
  #
  # The reason for keeping track of these separately is to prevent them
  # from being confused with manual transactions. Although when this was
  # written, I had made manual transactions nestable. That has been
  # since explicitly disallowed by Blueprints. I am not sure if this
  # code is actually needed anymore (if it was refactored out).
  #
  # TODO: the method names in this module need to be cleaned up.
  # TODO: some methods may be able to be eliminated.
  module ManagedTransactionsMixin
    def manage_transactions=(v)
      @manage_transactions = v
    end

    def manage_transactions?
      @manage_transactions = true unless defined? @manage_transactions
      @manage_transactions
    end
    alias manage_transactions manage_transactions?

    def unmanaged_transactions
      old_value = manage_transactions
      @manage_transactions = false
      yield
    ensure
      @manage_transactions = old_value
    end

    def managed_transactions
      if manage_transactions?
        manual_transactions { yield }
      else
        yield
      end
    end

    def managed_manual_transaction
      if manage_transactions?
        manual_transaction { yield }
      else
        yield
      end
    end

    def managed_transaction
      if manage_transactions?
        transaction { yield }
      else
        yield
      end
    end

    def managed_start_transaction
      begin_transaction if manage_transactions?
    end

    def managed_commit_transaction
      commit_transaction if manage_transactions?
    end

    def managed_checkpoint
      checkpoint if manage_transactions?
    end
  end

  # This is included into graphs that don't support transactions so that
  # their interface is the same as for graphs that do support them.
  #
  # All methods in this module do nothing but yield or return values
  # that match those in {GraphTransactionsMixin}
  module GraphTransactionsStub
    def in_transaction?
      false
    end

    def manual_transaction
      yield
    end

    def manual_transactions
      yield
    end

    def transaction
      yield
    end

    def begin_transaction
    end

    def commit_transaction
    end

    def rollback_transaction
    end

    def checkpoint
    end
  end

  # Add features to transactions to allow them to be more rubyish and
  # more convenient to use.
  #
  # TODO: the method names in this module need to be cleaned up.
  # TODO: some methods may be able to be eliminated.
  module GraphTransactionsMixin
    def self.included(target)
      target.send :protected, :startTransaction, :start_transaction
    end

    def in_transaction?
      Pacer.graphs_in_transaction.include? self
    end

    def manual_transaction
      manual_transactions do
        transaction do
          yield
        end
      end
    end

    def manual_transactions
      original_buffer_size = getMaxBufferSize
      if original_buffer_size != 0
        begin
          puts "transaction buffer size reset to 0 (MANUAL)" if Pacer.verbose == :very
          setMaxBufferSize 0
          yield
        rescue Exception
          rollback_transaction if in_transaction?
          raise
        ensure
          puts "transaction buffer size reset to #{ original_buffer_size }" if Pacer.verbose == :very
          setMaxBufferSize original_buffer_size
        end
      else
        yield
      end
    end

    def transaction
      begin_transaction
      conclusion = TransactionalGraph::Conclusion::FAILURE
      begin
        catch :transaction_failed do
          yield
          conclusion = TransactionalGraph::Conclusion::SUCCESS
        end
      rescue Exception
        puts "transaction aborted" if Pacer.verbose == :very
        raise
      ensure
        puts "transaction finished #{ conclusion }" if Pacer.verbose == :very
        stop_transaction conclusion
        Pacer.graphs_in_transaction.delete self
      end
    end

    def begin_transaction
      r = startTransaction
      Pacer.graphs_in_transaction << self
      puts "transaction started" if Pacer.verbose == :very
      r
    end

    def commit_transaction
      r = stop_transaction TransactionalGraph::Conclusion::SUCCESS
      Pacer.graphs_in_transaction.delete self
      puts "transaction committed" if Pacer.verbose == :very
      r
    end

    def rollback_transaction
      r = stop_transaction TransactionalGraph::Conclusion::FAILURE
      Pacer.graphs_in_transaction.delete self
      puts "transaction rolled back" if Pacer.verbose == :very
      r
    end

    def checkpoint(success = true)
      if success
        commit_transaction
      else
        rollback_transaction
      end
      begin_transaction
      Pacer.graphs_in_transaction << self
    end

  end
end
