module Pacer
  import com.tinkerpop.blueprints.pgm.TransactionalGraph

  def self.graphs_in_transaction
    @graphs ||= Set[]
  end

  module Graph
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
        ensure
          puts "transaction mode reset to #{ original_mode }" if Pacer.verbose == :very
          set_transaction_mode original_mode
        end
      else
        yield
      end
    end

    def transaction
      Pacer.graphs_in_transaction << self
      start_transaction
      conclusion = TransactionalGraph::Conclusion::FAILURE
      begin
        catch :transaction_failed do
          yield
          conclusion = TransactionalGraph::Conclusion::SUCCESS
        end
      rescue IRB::Abort
        puts "transaction aborted" if Pacer.verbose == :very
      ensure
        puts "transaction finished #{ conclusion }" if Pacer.verbose == :very
        stop_transaction conclusion
        Pacer.graphs_in_transaction.delete self
      end
    end

    def start_transaction
      startTransaction
    end

    def commit_transaction
      r = stop_transaction TransactionalGraph::Conclusion::SUCCESS
      Pacer.graphs_in_transaction.delete self
      r
    end

    def rollback_transaction
      r = stop_transaction TransactionalGraph::Conclusion::FAILURE
      Pacer.graphs_in_transaction.delete self
      r
    end

    def checkpoint
      commit_transaction
      start_transaction
      Pacer.graphs_in_transaction << self
    end
  end
end
