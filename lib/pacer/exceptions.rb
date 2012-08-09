module Pacer
  class Error < StandardError; end
    class UserError < Error; end
      class ElementNotFound < UserError; end
      class ElementExists < UserError; end

    class LogicError < Error; end
      class ClientError < LogicError; end
        class ArgumentError < ClientError; end

        class TransactionConcludedError < ClientError; end
        class NestedTransactionRollback < ClientError; end
        class NestedMockTransactionRollback < NestedTransactionRollback; end
        class MockTransactionRollback < ClientError; end
        class UnsupportedOperation < ClientError; end

      class InternalError < LogicError; end
    class TransientError < Error; end
end

