require 'spec_helper'

for_tg(:read_only) do
  use_grateful_dead_data :read_only

  describe Pacer::Filter::FutureFilter do
    let(:artists) { graph.v(:type => 'artist') }

    context 'artists who wrote songs' do
      let(:writers) { artists.lookahead { |v| v.in_e(:written_by) } }

      it 'should have less writers than artists' do
        writers.count.should < artists.count
      end

      it 'should not be duplicated' do
        writers.uniq.to_a.should == writers.to_a
      end
    end

    context 'prolific songwriters' do
      let(:names) { artists.lookahead { |v| v.in_e(:written_by)[30] }[:name].to_set }

      let(:names_over_30) do
        # this is a bit slow...it's how I got the list
        # hash = Hash.new 0
        # graph.v(:type => 'song').each { |v| v.out_e(:written_by).in_v[:name].each { |name| hash[name] += 1 } }
        # hash.select { |name, count| count > 30 }.map { |name, _| name }.to_set
        Set['Traditional', 'Hunter', 'Bob_Dylan']
      end

      it 'should only include writers who have written at least 31 songs' do
        names.should == names_over_30
      end
    end
  end
end
