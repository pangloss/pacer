class Rspec::GraphRunner
  def initialize(*graphs)
    @graphs = graphs.map { |s| s.to_s.downcase.split(/\s*,\s*/) }.flatten.map { |s| s.strip }.reject { |s| s == '' }
  end

  def inspect
    if @graphs.empty?
      "Testing all graphs."
    else
      "Testing graphs: #{ @graphs.join ', ' }."
    end
  end

  def all(usage_style = :read_write, indices = true, &block)
    tg(usage_style, indices, &block)
  end

  def use_graph?(name)
    if @graphs.empty?
      true
    else
      @graphs.include? name
    end
  end

  def tg(usage_style = :read_write, indices = true, &block)
    return unless use_graph? 'tg'
    describe 'tg' do
      let(:graph) do
        g = Pacer.tg
        unless indices
          g.drop_index :vertices
          g.drop_index :edges
        end
        g
      end
      let(:graph2) { Pacer.tg }
      instance_eval(&block)
    end
  end

protected

  def for_graph(name, usage_style, indices, transactions, source_graph_1, source_graph_2, unindexed_graph, block)
    return unless use_graph? name
    describe name do
      let(:graph) do
        if indices
          source_graph_1
        else
          unindexed_graph
        end
      end
      let(:graph2) do
        source_graph_2
      end
      if usage_style == :read_only
        before(:all) do
          source_graph_1.v.delete!
          source_graph_2.v.delete!
          unindexed_graph.v.delete! if unindexed_graph
        end
      end
      around do |spec|
        if usage_style == :read_write
          source_graph_1.v.delete!
          source_graph_2.v.delete!
          unindexed_graph.v.delete! if unindexed_graph
        end
        if transactions and spec.use_transactions?
          graph.manual_transactions do
            graph2.manual_transactions do
              begin
                graph.begin_transaction
                graph2.begin_transaction
                spec.run
              ensure
                graph.rollback_transaction rescue nil
                graph2.rollback_transaction rescue nil
              end
            end
          end
        else
          spec.run
        end
      end
      instance_eval(&block)
    end
  end
end

