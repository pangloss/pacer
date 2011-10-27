require 'spec_helper'

Run.tg(:read_only) do
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

    context 'multi-step traversal' do
      # Artists who wrote both covers and original songs...???...

      subject do
        artists.lookahead { |v| v.in(:written_by, :song_type => 'cover').out(:written_by).in(:written_by).where('song_type != "cover"') }
      end

      it { subject.count.should == 5 }
    end
  end

  describe Pacer::Filter::FutureFilter, '(negative)' do
    context 'artists who did not write songs' do
      def people
        [ "Daryl_Hall",
          "Hall_and_Oates",
          "Peter_Krug"
        ].to_route.map(:graph => graph, :element_type => :vertex) { |name| graph.v(:name => name).first }
      end
      def wrote_songs
        people.lookahead { |v| v.in_e(:written_by) }
      end
      def no_songs
        people.neg_lookahead { |v| v.in_e(:written_by) }
      end

      it 'should have a non songwriting artist' do
        no_songs.count.should == 1
      end

      it 'should have 3 people' do
        people.count.should == 3
      end
      
      it 'should have 2 songwriters' do
        wrote_songs.count.should == 2
      end

      it 'should combine the two types of artists to get the full list' do
        (wrote_songs.element_ids.to_a + no_songs.element_ids.to_a).sort.should == people.element_ids.to_a.sort
      end
    end
  end

  describe 'bug: ruby pipe was not calling reset on the next pipe in the chain' do
    let!(:a) { graph.create_vertex :type => 'a' }
    let!(:b) { graph.create_vertex :type => 'a' }
    let!(:c) { graph.create_vertex :type => 'a' }
    let!(:x) { graph.create_vertex :type => 'b' }
    let!(:y) { graph.create_vertex :type => 'b' }
    before do
      x.add_edges_to :has, [a,b,c] 
      y.add_edges_to :has, c 
    end

    subject do
      graph.v(type:'b').lookahead { |r| r.out(:has).only([a,b]) } 
    end
    its(:to_a) { should == [x] }
  end
end
