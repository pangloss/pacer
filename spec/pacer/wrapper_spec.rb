require 'spec_helper'
require 'pacer/graph/element_mixin_spec'

for_each_graph do
  it_uses Pacer::ElementMixin do

    let(:v0) { graph.create_vertex({ :name => 'eliza' }, Tackle::SimpleMixin) }
    let(:v1) { graph.create_vertex({ :name => 'darrick' }, Tackle::SimpleMixin) }
    let(:e0) { graph.create_edge nil, v0, v1, :links, Tackle::SimpleMixin }
    let(:e1) { graph.create_edge nil, v0, v1, :relinks, Tackle::SimpleMixin }
  end
end
