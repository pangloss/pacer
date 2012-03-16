require 'spec_helper'

module Pacer::Filter::PropertyFilter

  Run.tg do
    describe Filters do
      subject { filters }

      context 'no properties' do
        let(:filters) { Pacer::Route.filters [] }

        its(:any?) { should be_false }
      end

      context 'no properties' do
        let(:filters) { Pacer::Route.filters [Tackle::SimpleMixin] }

        its(:any?) { should be_true }
        its(:extensions_only?) { should be_true }
        its(:extensions) { should == [Tackle::SimpleMixin] }
        its(:route_modules) { should be_empty }
        its(:wrapper) { should be_nil }
        its(:blocks) { should be_empty }
        its(:properties) { should be_empty }
      end

      context 'simple properties' do
        let(:filters) { Pacer::Route.filters([name: 'Darrick', nickname: 'pangloss']) }

        its(:any?) { should be_true }
        its(:extensions_only?) { should be_false }
        its(:extensions) { should be_empty }
        its(:route_modules) { should be_empty }
        its(:wrapper) { should be_nil }
        its(:blocks) { should be_empty }
        its(:properties) { should == [ %w[ name Darrick ], %w[ nickname pangloss ] ] }
      end

      context 'with extensions' do
        let(:filters) { Pacer::Route.filters([TP::Person, name: 'Darrick', nickname: 'pangloss']) }

        its(:any?) { should be_true }
        its(:extensions) { should == [TP::Person] }
        its(:extensions_only?) { should be_false }
        its(:route_modules) { should be_empty }
        its(:wrapper) { should be_nil }
        its(:blocks) { should be_empty }
        its(:properties) { should == [ %w[ type person ], %w[ name Darrick ], %w[ nickname pangloss ] ] }

        context '+ indices' do
          before do
            filters.graph = graph
            filters.indices = graph.getIndices
            filters.choose_best_index = true
            filters.search_manual_indices = true
          end

          def find_index
            @idx, @key, @value = filters.best_index(:vertex)
          end

          it 'should use the automatic index' do
            find_index
            @idx.should be_a Java::ComTinkerpopBlueprintsPgmImplsTg::TinkerAutomaticIndex
          end

          it 'should use the first key and value' do
            find_index
            @key.should == 'type'
            @value.should == 'person'
          end

          context '+ data' do
            before do
              5.times { graph.create_vertex type: 'person', name: 'Someone', nickname: nil }
              graph.create_vertex type: 'person', name: 'Darrick', nickname: 'therealdarrick'
            end

            it 'should use the non-empty key when searching manual indices' do
              find_index
              @key.should == 'name'
              @value.should == 'Darrick'
            end

            it 'should use the empty key' do
              filters.search_manual_indices = false
              find_index
              @key.should == 'nickname'
              @value.should == 'pangloss'
            end

            context '+ match' do
              before do
                3.times { graph.create_vertex type: 'person', name: 'Immitator', nickname: 'pangloss' }
              end

              let!(:match) do
                graph.create_vertex type: 'person', name: 'Darrick', nickname: 'pangloss'
              end

              it 'should use the smallest key' do
                find_index
                @key.should == 'name'
                @value.should == 'Darrick'
              end
            end
          end
        end
      end

      context 'with route module' do
        # TODO: should this feature be removed?
        let(:filters) { Pacer::Route.filters [TP::Pangloss] }

        its(:any?) { should be_true }
        its(:extensions_only?) { should be_false }
        its(:extensions) { should == [TP::Pangloss] }
        its(:route_modules) { should == [TP::Pangloss] }
        its(:wrapper) { should be_nil }
        its(:blocks) { should be_empty }
        its(:properties) { should be_empty }
      end

      context 'with manual index' do
        let(:filters) { Pacer::Route.filters [tokens: { short: '555555' }, name: 'Darrick'] }

        its(:any?) { should be_true }
        its(:extensions) { should be_empty }
        its(:route_modules) { should be_empty }
        its(:wrapper) { should be_nil }
        its(:blocks) { should be_empty }
        its(:properties) { should == [['tokens', short: '555555'], %w[ name Darrick ]] }
      end
    end
  end
end
