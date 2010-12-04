module Pacer
  import com.tinkerpop.blueprints.pgm.TransactionalGraph

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
          set_transaction_mode TransactionalGraph::Mode::MANUAL
          yield
        ensure
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
      ensure
        stop_transaction conclusion
      end
    end

    def commit_transaction
      stop_transaction TransactionalGraph::Conclusion::SUCCESS
    end

    def rollback_transaction
      stop_transaction TransactionalGraph::Conclusion::FAILURE
    end

    def checkpoint
      commit_transaction
      start_transaction
    end
  end
end
