require 'spec_helper'

Run.tg(:read_only) do
  use_pacer_graphml_data(:read_only)

  describe Pacer::Filter::LoopFilter do
    describe '#loop' do
      it 'is a ClientError if no control block is specified' do
        lambda do
          graph.v.loop { |v| v.out }.in.to_a
        end.should raise_error Pacer::ClientError
      end

      it 'is a ClientError if no control block is specified' do
        lambda do
          graph.v.loop { |v| v.out }.to_a
        end.should raise_error Pacer::ClientError
      end

      describe 'control block' do
        it 'should wrap elements' do
          yielded = false
          graph.v.loop { |v| v.out }.while do |el|
            el.should be_a Pacer::Wrappers::VertexWrapper
            yielded = true
          end.first
          yielded.should be_true
        end

        it 'should wrap path elements' do
          yielded = false
          graph.v.loop { |v| v.out }.while do |el, depth, path|
            el.should be_a Pacer::Wrappers::VertexWrapper
            depth.should == 0
            path.should be_a Array
            path.length.should == 1
            path.each do |e|
              e.should be_a Pacer::Wrappers::VertexWrapper
            end
            yielded = true
          end.first
          yielded.should be_true
        end

        context 'project tree' do
          let(:depths) do
            [ 0,       # pangloss
              1,       # pacer
              2, 2, 2, # gremlin, pipes, blueprints
              3, 3, 3, # gremlin>blueprints, gremlin>pipes, pipes>blueprints
              4        # gremlin>pipes>blueprints
            ]
          end

          let(:route) do
            pangloss.loop { |v| v.out }.while do |el, depth, path|
              depth.should == depths.shift
              path.length.should == depth + 1
              true
            end
          end

          it 'should exhaust the depths list' do
            route.to_a
            depths.should be_empty
          end

          it 'should have the right results' do
            route[:name].to_a.should == %w[
              pangloss
              pacer
              gremlin pipes blueprints
              blueprints pipes blueprints
              blueprints
            ]
          end
        end

        let(:paths) do
          [ %w[ pangloss ],
            %w[ pangloss pacer ],
            %w[ pangloss pacer gremlin ],
            %w[ pangloss pacer pipes ],
            %w[ pangloss pacer blueprints ],
            %w[ pangloss pacer gremlin blueprints ],
            %w[ pangloss pacer gremlin pipes ],
            %w[ pangloss pacer pipes blueprints ],
            %w[ pangloss pacer gremlin pipes blueprints ] ]
        end

        it 'should have correct paths with control block paths' do
          route = pangloss.
            loop { |v| v.out }.
            while { |el, depth, path| true }.
            paths
          route.collect { |p| p.map { |e| e[:name] } }.should == paths
        end

        it 'should have correct paths without control block paths' do
          route = pangloss.
            loop { |v| v.out }.
            while { |el| true }.
            paths
          route.collect { |p| p.map { |e| e[:name] } }.should == paths
        end
      end
    end

    describe '#repeat' do
      it 'should apply the route part twice' do
        route = graph.v.repeat(2) { |tail| tail.out_e.in_v }.inspect
        route.should == graph.v.out_e.in_v.out_e.in_v.inspect
      end

      it 'should apply the route part 3 times' do
        route = graph.v.repeat(3) { |tail| tail.out_e.in_v }.inspect
        route.should == graph.v.out_e.in_v.out_e.in_v.out_e.in_v.inspect
      end

      describe 'with a range' do
        let(:start) { graph.vertex(0).v }
        subject { start.repeat(1..3) { |tail| tail.out_e.in_v[0] } }

        it 'should be equivalent to executing each path separately' do
          pending
          subject.to_a.should == [start.out_e.in_v.first,
                                  start.out_e.in_v.out_e.in_v.first,
                                  start.out_e.in_v.out_e.in_v.out_e.in_v.first]
        end
      end
    end
  end
end
