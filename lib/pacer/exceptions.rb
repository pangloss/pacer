module Pacer
  class Error < StandardError; end
    class UserError < Error; end
      class ElementNotFound < UserError; end
      class ElementExists < UserError; end

    class LogicError < Error; end
      class ClientError < LogicError; end
        class TransactionError < ClientError; end
          class TransactionConcludedError < TransactionError; end
          class NestedTransactionError < TransactionError; end
          class NestedTransactionRollback < TransactionError; end
          class NestedMockTransactionRollback < NestedTransactionRollback; end
          class MockTransactionRollback < TransactionError; end
        class UnsupportedOperation < ClientError; end

      class InternalError < LogicError; end
    class TransientError < Error; end
end

