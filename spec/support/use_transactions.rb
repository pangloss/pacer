module RSpec
  module Core
    class Example
      module ProcsyTransactions
        def use_transactions?
          find_metadata(metadata, :transactions) != false
        end

        def find_metadata(hash, key)
          return unless hash.is_a? Hash
          if hash.key? key
            hash[key]
          elsif hash.key? :example_group
            find_metadata(hash[:example_group], key)
          end
        end
      end

      if not defined? Procsy or Procsy.class == Module
        # RSpec version >= '2.5.0'
        module Procsy
          include ProcsyTransactions
        end
      else
        class Procsy
          include ProcsyTransactions
        end
      end
    end
  end
end
