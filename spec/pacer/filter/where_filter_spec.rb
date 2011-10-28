require 'spec_helper'


Run.tg(:read_only) do
  use_pacer_graphml_data(:read_only)
  before :all do
    n = 0
    graph.v.each { |v| v[:number] = n += 1 }
    graph.vertex('0')[:note] = "note"
    graph.vertex('2')[:note] = "note"
  end

  describe Pacer::Filter::WhereFilter do
    context "name = 'blueprints'" do
      subject { graph.v.where("name = 'blueprints'")[:name] }
      its(:count) { should == 1 }
      its(:first) { should == 'blueprints' }
    end

    context "name != nil" do
      subject { graph.v.where("name != nil") }
      its(:count) { should == 7 }
    end

    context :note do
      subject { graph.v.where :note }
      its(:count) { should == 2 }
    end

    context '#unless(:note)' do
      subject { graph.v.unless :note }
      its(:count) { should == 5 }
    end

    context 'name and note' do
      subject { graph.v.where 'name and note' }
      its(:count) { should == 2 }
    end

    context 'name and not note' do
      subject { graph.v.where 'name and not note' }
      its(:count) { should == 5 }
    end

    context '#unless(name and not note)' do
      subject { graph.v.unless 'name and not note' }
      its(:count) { should == 2 }
    end

    context 'name and type == "project"' do
      subject { graph.v.where 'note and type == "project"' }
      its(:count) { should == 1 }
    end

    context '#unless(:name)' do
      subject { graph.v.unless :name }
      its(:count) { should == 0 }
    end

    context "name = nil" do
      subject { graph.v.where("name = nil") }
      its(:count) { should == 0 }
    end


    context 'with number' do
      context "number = 1" do
        subject { graph.v.where("number = 1") }
        its(:count) { should == 1 }
      end

      context "number >= 2" do
        subject { graph.v.where("number >= 2") }
        its(:count) { should == 6 }
      end

      context "#unless(number >= 2)" do
        subject { graph.v.unless("number >= 2") }
        its(:count) { should == 1 }
      end

      context "number % 2 == 0" do
        subject { graph.v.where("number % 2 == 0") }
        its(:count) { should == 3 }
      end

      context "number % 2 == 0 + 1" do
        subject { graph.v.where("number % 2 == 0 + 1") }
        its(:count) { should == 4 }
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

    context ":type == type and (name = 'blueprints' or name = 'pipes') with 'project'" do
      subject { graph.v.where(":type == type and (name = 'blueprints' or name = 'pipes')", :type => 'project') }
      its(:count) { should == 2 }
    end

    context "yield :fun" do
      subject { graph.v.where("yield :fun", :fun => proc { |v| v[:name] == 'blueprints' }) }
      its(:count) { should == 1 }
    end

    context "type = :type and (yield(:fun) or name = :name1) with 'person'" do
      subject { graph.v.where("type = :type and (yield(:fun) or name = :name2)",
                              :type => 'project', :fun => proc { |v| v[:name] == 'blueprints' }, :name2 => 'pipes') }
      its(:count) { should == 2 }
    end
  end
end
