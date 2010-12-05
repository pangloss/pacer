require 'spec_helper'

describe GraphRoute do
  before do
    @g = Pacer.tg
  end

  describe '#v' do
    it { @g.v.should be_an_instance_of(VerticesRoute) }
  end

  describe '#e' do
    it { @g.e.should be_an_instance_of(EdgesRoute) }
  end

  it { @g.should_not be_a(RouteOperations) }
end
