require 'spec_helper'

# New tests:
Run.tg(:read_only) do
  use_pacer_graphml_data(:read_only)

  describe RouteOperations do
    describe '#most_frequent' do
      context '()' do
        subject { graph.v[:type].most_frequent }
        it { should == 'project' }
      end

      context '(0)' do
        subject { graph.v[:type].most_frequent(0) }
        it { should == 'project' }
      end

      context '(1)' do
        subject { graph.v[:type].most_frequent(1) }
        it { should == 'person' }
      end

      context '(0..1)' do
        subject { graph.v[:type].most_frequent(0..1) }
        it { should be_a Pacer::Core::Route }
        its(:element_type) { should == :object }
        its(:to_a) { should == ['project', 'person'] }
      end

      context '(0, true)' do
        subject { graph.v[:type].most_frequent(0, true) }
        it { should == ['project', 4] }
      end

      context '(1, true)' do
        subject { graph.v[:type].most_frequent(1, true) }
        it { should == ['person', 2] }
      end

      context '(0..1, true)' do
        subject { graph.v[:type].most_frequent(0..1, true) }
        it { should == [['project', 4], ['person', 2]] }
      end
    end
  end
end

Run.tg do
  use_pacer_graphml_data

  describe RouteOperations do
    before do
      setup_data
    end

    describe '#build_index' do
      context "('new_index', 'k') { count += 1 }", :transactions => true do
        it 'should build the index with raw elements' do
          count = 0
          index = graph.v.build_index('new_index', 'k', 'name')
          index.should_not be_nil
          index.all('k', 'pangloss').count.should == 1
        end

        it 'should build the index with wrapped elements' do
          count = 0
          index = graph.v(TP::Person).build_index('new_index', 'k', 'name')
          index.should_not be_nil
          index.all('k', 'pangloss').count.should == 1
        end

        it 'should do nothing if there are no elements' do
          count = 0
          index = graph.v.limit(0).build_index('new_index', 'k', 'name')
          index.should be_nil
        end

        after do
          graph.drop_index 'new_index'
        end
      end
    end
  end
end
