require 'spec_helper'

describe PathsRoute do
  before :all do
    @g = Pacer.tg 'spec/data/pacer.graphml'
  end

  describe '#paths' do
    it 'should return the paths between people and projects' do
      Set[*@g.v(:type => 'person').out_e.in_v(:type => 'project').paths.map(&:to_a)].should ==
        Set[[@g.vertex(0), @g.edge(0), @g.vertex(1)],
            [@g.vertex(5), @g.edge(1), @g.vertex(4)],
            [@g.vertex(5), @g.edge(13), @g.vertex(2)],
            [@g.vertex(5), @g.edge(12), @g.vertex(3)]]
    end

    it 'should include all elements traversed' do
      @g.v.out_e.in_v.paths.each do |path|
        path[0].should be_an_instance_of(Pacer::TinkerVertex)
        path[1].should be_an_instance_of(Pacer::TinkerEdge)
        path[2].should be_an_instance_of(Pacer::TinkerVertex)
        path.length.should == 3
      end
    end

  end

  describe '#transpose' do
    it 'should return the paths between people and projects' do
      Set[*@g.v(:type => 'person').out_e.in_v(:type => 'project').paths.transpose].should ==
        Set[[@g.vertex(0), @g.vertex(5), @g.vertex(5), @g.vertex(5)],
            [@g.edge(0), @g.edge(1), @g.edge(13), @g.edge(12)],
            [@g.vertex(1), @g.vertex(4), @g.vertex(2), @g.vertex(3)]]
    end
  end

  describe '#subgraph' do
    before do
      @sg = @g.v(:type => 'person').out_e.in_v(:type => 'project').subgraph

      @vertices = @g.v(:type => 'person').to_a + @g.v(:type => 'project').to_a
      @edges = @g.v(:type => 'person').out_e(:wrote)
    end

    it { Set[*@sg.v.element_ids].should == Set[*@vertices.map { |v| v.element_id }] }
    it { Set[*@sg.e.element_ids].should == Set[*@edges.map { |e| e.element_id }] }

    it { @sg.e.labels.uniq.should == ['wrote'] }
    it { Set[*@sg.v.map { |v| v.properties }].should == Set[*@vertices.map { |v| v.properties }] }
  end
end

