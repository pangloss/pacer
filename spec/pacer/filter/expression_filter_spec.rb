require 'spec_helper'


for_tg(:read_only) do
  use_pacer_graphml_data(:read_only)
  describe Pacer::Filter::ExpressionFilter, :focus => true do
    describe 'Parser' do
      def int_eq(a, b = nil)
        b ||= a
        { :statement => { :left => { :int => a.to_s }, :op => '=', :right => { :int => b.to_s } } }
      end

      context "name = 'Hunter'" do
        subject { graph.v.where "name = 'Hunter'" }
        its(:parsed) { should == { :statement => { :left => { :prop => 'name' }, :op => '=', :right => { :str => 'Hunter' } } } }
      end

      context "'Hunter' = name" do
        subject { graph.v.where "'Hunter' = name" }
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
