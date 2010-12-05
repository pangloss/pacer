require 'spec_helper'

describe VerticesRoute do
  before do
    @g = Pacer.tg 'spec/data/pacer.graphml'
  end

  describe '#out_e' do
    it { @g.v.out_e.should be_an_instance_of(EdgesRoute) }
    it { @g.v.out_e(:label).should be_an_instance_of(EdgesRoute) }
    it { @g.v.out_e(:label) { |x| true }.should be_an_instance_of(EdgesRoute) }
    it { @g.v.out_e { |x| true }.should be_an_instance_of(EdgesRoute) }

    it { Set[*@g.v.out_e].should == Set[*@g.edges] }

    it { @g.v.out_e.count.should >= 1 }

    it 'with label filter should work with path generation' do
      paths = @g.v.out_e.in_v.in_e { |e| e.label == 'wrote' }.out_v.paths.map(&:to_a)
      @g.v.out_e.in_v.in_e(:wrote).out_v.paths.map(&:to_a).should == paths
    end
  end
end

