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
      @manage_transactions = true if @manage_transactions.nil?
      @manage_transactions
    end
    alias manage_transactions manage_transactions?

    def unmanaged_transactions
      old_value = @manage_transactions
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
      original_mode = get_transaction_mode
      if original_mode != TransactionalGraph::Mode::MANUAL
        begin
          puts "transaction mode reset to MANUAL" if Pacer.verbose == :very
          set_transaction_mode TransactionalGraph::Mode::MANUAL
          yield
        rescue Exception
          rollback_transaction if in_transaction?
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
