require 'spec_helper'


Run.tg(:read_only) do
  use_pacer_graphml_data(:read_only)

  describe Pacer::Filter::ExpressionFilter do
    context "name = 'blueprints'" do
      subject { graph.v.where("name = 'blueprints'")[:name] }
      its(:count) { should == 1 }
      its(:first) { should == 'blueprints' }
    end

    context "name != nil" do
      subject { graph.v.where("name != nil") }
      its(:count) { should == 7 }
    end

    context "name = nil" do
      subject { graph.v.where("name = nil") }
      its(:count) { should == 0 }
    end

    context 'with number' do
      context "number = 1" do
        before do
          n = 0
          graph.v(:type => 'person').each { |v| v[:number] = n += 1 }
        end
        subject { graph.v.where("number = 1") }
        its(:count) { should == 1 }
      end

      context "number >= 1" do
        before do
          n = 0
          graph.v(:type => 'person').each { |v| v[:number] = n += 1 }
        end
        subject { graph.v.where("number >= 1") }
        its(:count) { should == 2 }
      end
    end

    context "name = 'blueprints' or name = 'pipes'" do
      subject { graph.v.where("name = 'blueprints' or name = 'pipes'")[:name] }
      its(:count) { should == 2 }
      its(:to_a) { should == ['blueprints', 'pipes'] }
    end

    context "type = 'person' and (name = 'blueprints' or name = 'pipes')" do
      subject { graph.v.where("type = 'person' and (name = 'blueprints' or name = 'pipes')") }
      its(:count) { should == 0 }
    end

    context "type = 'project' and (name = 'blueprints' or name = 'pipes') or true" do
      subject { graph.v.where("type = 'project' and (name = 'blueprints' or name = 'pipes') or true") }
      its(:count) { should == 7 }
    end

    context "type = :type and (name = 'blueprints' or name = 'pipes') with 'person'" do
      subject { graph.v.where("type = :type and (name = 'blueprints' or name = 'pipes')", :type => 'person') }
      its(:count) { should == 0 }
    end

    context "type = :type and (name = 'blueprints' or name = 'pipes') with 'project'" do
      subject { graph.v.where("type = :type and (name = 'blueprints' or name = 'pipes')", :type => 'project') }
      its(:count) { should == 2 }
    end

    context ":type = type and (name = 'blueprints' or name = 'pipes') with 'project'" do
      subject { graph.v.where(":type = type and (name = 'blueprints' or name = 'pipes')", :type => 'project') }
      its(:count) { should == 2 }
    end

    context "&fun" do
      subject { graph.v.where("&fun", :fun => proc { |v| v[:name] == 'blueprints' }) }
      its(:count) { should == 1 }
    end

    context "type = :type and (&fun or name = :name1) with 'person'" do
      subject { graph.v.where("type = :type and (&fun or name = :name2)",
                              :type => 'project', :fun => proc { |v| v[:name] == 'blueprints' }, :name2 => 'pipes') }
      its(:count) { should == 2 }
    end




    describe 'Parser' do
      def int_eq(a, b = nil)
        b ||= a
        { :statement => { :left => { :int => a.to_s }, :op => '=', :right => { :int => b.to_s } } }
      end

      context "name = 'Hunter'" do
        subject { graph.v.where "name = 'Hunter'" }
        its(:parsed) { should == { :statement => { :left => { :prop => 'name' }, :op => '=', :right => { :str => 'Hunter' } } } }
      end

      context '"Hunter" = name' do
        subject { graph.v.where '"Hunter" = name' }
        its(:parsed) { should == { :statement => { :left => { :str => 'Hunter' }, :op => '=', :right => { :prop => 'name' } } } }
      end

      context "&block_var" do
        subject { graph.v.where "&block_var" }
        its(:parsed) { should == { :statement => { :proc => 'block_var' } } }
      end

      context '1.1 > 0.5' do
        subject { graph.v.where "1.1 > 0.5" }
        its(:parsed) { should == { :statement => { :left => { :float => '1.1' }, :op => '>', :right => { :float => '0.5' } } } }
      end

      context '1.1 >= 0.5' do
        subject { graph.v.where "1.1 >= 0.5" }
        its(:parsed) { should == { :statement => { :left => { :float => '1.1' }, :op => '>=', :right => { :float => '0.5' } } } }
      end

      context '1.1 < 0.5' do
        subject { graph.v.where "1.1 < 0.5" }
        its(:parsed) { should == { :statement => { :left => { :float => '1.1' }, :op => '<', :right => { :float => '0.5' } } } }
      end

      context '1.1 <= 0.5' do
        subject { graph.v.where "1.1 <= 0.5" }
        its(:parsed) { should == { :statement => { :left => { :float => '1.1' }, :op => '<=', :right => { :float => '0.5' } } } }
      end

      context '1.1 == 0.5' do
        subject { graph.v.where "1.1 == 0.5" }
        its(:parsed) { should == { :statement => { :left => { :float => '1.1' }, :op => '==', :right => { :float => '0.5' } } } }
      end

      context '1.1 != 0.5' do
        subject { graph.v.where "1.1 != 0.5" }
        its(:parsed) { should == { :statement => { :left => { :float => '1.1' }, :op => '!=', :right => { :float => '0.5' } } } }
      end

      context '{a "freeformin\'" {property\} () $ #{ cRaZY! \}} != name' do
        subject { graph.v.where '{a "freeformin\'" {property\} () $ #{ cRaZY! \}} != name' }
        its(:parsed) { should == { :statement => { :left => { :prop => 'a "freeformin\'" {property\} () $ #{ cRaZY! \}' },
                                                   :op => '!=', :right => { :prop => 'name' } } } }
      end

      context "true" do
        subject { graph.v.where "true" }
        its(:parsed) { should == { :statement => { :bool => 'true' } } }
      end

      context "false" do
        subject { graph.v.where "false" }
        its(:parsed) { should == { :statement => { :bool => 'false' } } }
      end

      context "nil = nil" do
        subject { graph.v.where "nil = nil" }
        its(:parsed) { should == { :statement => { :left => { :null => 'nil' }, :op => '=', :right => { :null => 'nil' } } } }
      end

      context '(1=1)' do
        subject { graph.v.where '(1=1)' }
        its(:parsed) { should == { :group => int_eq(1) } }
      end

      context '(1=1 and 2 = 2)' do
        subject { graph.v.where '(1=1 and 2 = 2)' }
        its(:parsed) { should == { :group => { :and => [int_eq(1), int_eq(2)] } } }
      end

      context "1 = 2" do
        subject { graph.v.where '1 = 2' }
        its(:parsed) { should == int_eq(1, 2) }
      end

      context "1 = 1 and 2 = 2" do
        subject { graph.v.where "1 = 1 and 2 = 2" }
        its(:parsed) { should == { :and => [int_eq(1), int_eq(2)] } }
      end

      context "1 = 1 and 2 = 2 and 3 = 3" do
        subject { graph.v.where "1 = 1 and 2 = 2 and 3 = 3" }
        its(:parsed) { should == { :and => [int_eq(1), int_eq(2), int_eq(3)] } }
      end

      context "1 = 1 or 2 = 2" do
        subject { graph.v.where "1 = 1 or 2 = 2" }
        its(:parsed) { should == { :or => [int_eq(1), int_eq(2)] } }
      end

      context "1 = 1 or 2 = 2 or 3 = 3" do
        subject { graph.v.where "1 = 1 or 2 = 2 or 3 = 3" }
        its(:parsed) { should == { :or => [int_eq(1), int_eq(2), int_eq(3)] } }
      end

      context "1 = 1 or 2 = 2 and 3 = 3" do
        subject { graph.v.where "1 = 1 or 2 = 2 and 3 = 3" }
        its(:parsed) { should == { :or => [int_eq(1), { :and => [int_eq(2), int_eq(3)] }] } }
      end

      context "1 = 1 and 2 = 2 or 3 = 3" do
        subject { graph.v.where "1 = 1 and 2 = 2 or 3 = 3" }
        its(:parsed) { should == { :or => [{ :and => [int_eq(1), int_eq(2)] }, int_eq(3)] } }
      end

      context "1 = 1 and 2 = 2 or 3 = 3 and 4 = 4" do
        subject { graph.v.where "1 = 1 and 2 = 2 or 3 = 3 and 4 = 4" }
        its(:parsed) { should == { :or => [{ :and => [int_eq(1), int_eq(2)] }, { :and => [int_eq(3), int_eq(4)] }] } }
      end

      context "1 = 1 and (2 = 2 or 3 = 3) and 4 = 4" do
        subject { graph.v.where "1 = 1 and (2 = 2 or 3 = 3) and 4 = 4" }
        its(:parsed) { should == { :and => [int_eq(1), { :group => { :or => [int_eq(2), int_eq(3)] } }, int_eq(4)] } }
      end
    end
  end
end
