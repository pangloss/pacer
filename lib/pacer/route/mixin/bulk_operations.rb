module Pacer::Routes

  # Additional iteration methods that allow for rapid data
  # manipulation in transactional graphs. Bulk operations automatically
  # manage transactions in larger batches rather than on every
  # element created or removed or every property set.
  module BulkOperations
    # Like bulk_job that also returns an array of results
    def bulk_map(size = nil, target_graph = nil)
      result = []
      bulk_job(size, target_graph) do |e|
        result << yield(e)
      end
      result
    end

    # Iterates over each element in the route, controlling
    # transactions so that they are only committed once every
    # +size+ records.
    def bulk_job(size = nil, target_graph = nil)
      target_graph ||= graph
      if target_graph and not target_graph.in_bulk_job?
        begin
          target_graph.in_bulk_job = true
          size ||= target_graph.bulk_job_size
          counter = 0
          each_slice(size) do |slice|
            print counter if Pacer.verbose?
            counter += size
            target_graph.transaction do |commit, rollback|
              slice.each do |element|
                yield element
              end
            end
            print '.' if Pacer.verbose?
          end
        ensure
          puts '!' if Pacer.verbose?
          target_graph.in_bulk_job = false
        end
      elsif target_graph
        each do |element|
          yield element
        end
      else
        raise 'No graph in route for bulk job'
      end
    end
  end
end
