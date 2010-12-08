module Pacer
  import com.tinkerpop.blueprints.pgm.TransactionalGraph

  def self.graphs_in_transaction
    @graphs ||= Set[]
  end

  module ManagedTransactionsMixin
    def manage_transactions=(v)
      @manage_transactions = v
    end

    def manage_transactions?
      @manage_transactions ||= true
    end
    alias manage_transactions manage_transactions?

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
      start_transaction if manage_transactions?
    end

    def managed_commit_transaction
      commit_transaction if manage_transactions?
    end

    def managed_checkpoint
      checkpoint if manage_transactions?
    end
  end

  module GraphTransactionsStub
    def manual_transaction
      yield
    end

    def manual_transactions
      yield
    end

    def transaction
      yield
    end

    def start_transaction
    end

    def commit_transaction
    end

    def rollback_transaction
    end

    def checkpoint
    end
  end

  module GraphTransactionsMixin
    def manual_transaction
      manual_transactions do
        transaction do
          yield
        end
      end
    end

    def manual_transactions
      original_mode = get_transaction_mode
      if original_mode != TransactionalGraph::Mode::MANUAL
        begin
          puts "transaction mode reset to MANUAL" if Pacer.verbose == :very
          set_transaction_mode TransactionalGraph::Mode::MANUAL
          yield
        rescue IRB::Abort, Exception
          rollback_transaction if Pacer.graphs_in_transaction.include? self
          raise
        ensure
          puts "transaction mode reset to #{ original_mode }" if Pacer.verbose == :very
          set_transaction_mode original_mode
        end
      else
        yield
      end
    end

    def transaction
      start_transaction
      conclusion = TransactionalGraph::Conclusion::FAILURE
      begin
        catch :transaction_failed do
          yield
          conclusion = TransactionalGraph::Conclusion::SUCCESS
        end
      rescue IRB::Abort
        puts "transaction aborted" if Pacer.verbose == :very
        raise
      ensure
        puts "transaction finished #{ conclusion }" if Pacer.verbose == :very
        stop_transaction conclusion
        Pacer.graphs_in_transaction.delete self
      end
    end

    def start_transaction
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

    def checkpoint
      commit_transaction
      start_transaction
      Pacer.graphs_in_transaction << self
    end

    #protected :startTransaction
  end
end
