require 'spec_helper'

Run.all(:read_only, false) do
  around { |spec| spec.run if graph }
  use_pacer_graphml_data(:read_only)

  context Pacer::Core::Graph::GraphRoute do
    describe '#v' do
      subject { graph.v }
      it { should be_a_vertices_route }
      its(:to_a) { should_not be_empty }
    end

    describe '#e' do
      subject { graph.e }
      it { should be_an_edges_route }
      its(:to_a) { should_not be_empty }
    end

    subject { graph }
    it { should_not be_a(Pacer::Routes::RouteOperations) }

    describe '#filter' do
      it 'is not implemented' do
        expect { graph.filter(:a => 'b') }.to raise_error
      end
    end

    its(:result) { should == graph }
    its(:hide_elements) { should == true }

    context 'with vertex name indexed' do
      before :all do
        if graph
          graph.transaction do
            graph.v.build_index :name
          end
          graph.search_manual_indices = true
        end
      end

      after :all do
        if graph
          graph.transaction do
            graph.drop_index :name
          end
        end
      end

      context 'basic search' do
        subject { graph.v(:name => 'pangloss') }
        it { should be_a(Pacer::Filter::IndexFilter) }
        its(:to_a) { should_not be_empty }
        its(:count) { should == 1 }
      end

      context 'basic search 2' do
        subject { graph.v([{ :name => 'pangloss' }]) }
        it { should be_a(Pacer::Filter::IndexFilter) }
        its(:to_a) { should_not be_empty }
        its(:count) { should == 1 }
      end

      context 'basic search 3' do
        subject { graph.v({ :name => 'pangloss' }, { :type => 'person' } ) }
        its(:inspect) { should == '#<V-Index(name: "pangloss") -> V-Property(type=="person")>' }
        its(:to_a) { should_not be_empty }
        its(:count) { should == 1 }
      end

      context 'extension search' do
        subject { graph.v(TP::Person, :name => { :name => 'pangloss' }) }
        its(:inspect) { should == '#<V-Index(name: "pangloss") -> V-Property(TP::Person)>' }
        its(:extensions) { should include(TP::Person) }
        its(:to_a) { should_not be_empty }
        its(:count) { should == 1 }
      end

      context 'extension search 2' do
        subject { graph.v(TP::Pangloss) }
        its(:back) { should be_a(Pacer::Filter::IndexFilter) }
        its(:to_a) { should_not be_empty }
        its(:count) { should == 1 }
      end
    end

    pending 'with vertex auto index' do
      before :all do
        graph.build_automatic_index :v_auto, :vertex, [:type] if graph
      end

      after :all do
        graph.drop_index :v_auto if graph
      end

      subject { graph.v(:type => 'person') }
      it { should be_a(Pacer::Filter::IndexFilter) }
      its(:to_a) { should_not be_empty }
      its(:count) { should == 2 }
    end
  end
end
