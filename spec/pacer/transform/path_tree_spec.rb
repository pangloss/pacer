require 'spec_helper'

Run.tg :read_only do
  use_pacer_graphml_data :read_only

  describe Pacer::Transform::PathTree do
    let(:first) do
      graph.v(type: 'person').payload do |p|
        { pos: 'first',
          type: p[:type],
          name: p[:name] }
      end.lookahead { |v| v.out_e.in_v(type: 'project') }
    end
    let(:second) do
      first.out_e.in_v(type: 'project').payload do |prj|
        { pos: 'second',
          type: 'project',
          name: prj[:name] }
      end
    end
    let(:paths) { second.paths }
    let(:payloads) { paths.payloads }
    let(:compacted) { payloads.compact_paths }

    describe 'basic paths' do
      subject { paths }

      its(:count) { should == 4 }

      it 'should have 3 elements' do
        paths.each { |x| x.length.should == 3 }
      end
    end

    describe 'tree of paths' do
      subject { paths.tree }

      its(:count) { should == first.count }
      its(:first) { should be_a Array }

      it 'should be a tree' do
        (pangloss, wrote, pacer), (a2, e2, b2), (_, e3, b3), (_, e4, b4) = paths.to_a
        subject.to_a.should == [
          [pangloss, [wrote, [pacer]]],
          [a2, [e2, [b2]],
               [e3, [b3]],
               [e4, [b4]]]
        ]
      end
    end

    describe 'tree of payloads' do
      subject { payloads.tree }

      its(:count) { should == first.count }
      its(:first) { should be_a Array }

      it 'should be a tree' do
        (pangloss, wrote, pacer), (a2, _, b2), (_, _, b3), (_, _, b4) = payloads.to_a
        subject.to_a.should == [
          [pangloss, [wrote, [pacer]]],
          [a2, [nil, [b2],
                     [b3],
                     [b4]]]
        ]
      end
    end

    describe 'tree of compacted payloads' do
      subject { compacted.tree }

      its(:count) { should == first.count }
      its(:first) { should be_a Array }

      it 'should be a tree' do
        (pangloss, pacer), (a2, b2), (_, b3), (_, b4) = compacted.to_a
        subject.to_a.should == [
          [pangloss, [pacer]],
          [a2, [b2],
               [b3],
               [b4]]
        ]
      end
    end

    describe 'tree of compacted payloads by type' do
      subject { compacted.tree { |a, b| a[:type] == b[:type] } }

      it 'should be a tree, taking the first match' do
        pangloss, pacer = compacted.first
        subject.to_a.should == [
          [pangloss, [pacer]]
        ]
      end
    end
  end
end
