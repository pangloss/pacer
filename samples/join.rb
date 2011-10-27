# setup:
def setup_graph
  g = Pacer.tg
  person = g.create_vertex type: 'person' 
  20.times { g.create_vertex type: 'person' }
  g.v.each { |v| v.add_edges_to :friend, g.v.random(rand(10)) }
  20.times { g.create_vertex :type => 'product' }
  g.v(type: 'person').each { |person| g.v(type: 'product').random(rand(10)).each { |prod| prod.add_edges_to :rated, person, weight: rand(5) } }
  [g, person]
end

def groups1(person)
  groups = person.out.group.values_route(:default) { |friend| friend.out.is_not(person).in_e(:rated)[:weight] }
  groups.each { |g| g.set_values(:sum, g.values.sum) }
  groups.sort_by { |g| -g.values.sum }

  groups.reduce(0, :values) { |r, v| r + v }
end


def groups2(person)
  groups2 = person.v.collect_as(:person).out.collect_as(:friend, within: :person).out.is_not(person).in_e(:rated)[:weight].reduce_to(:friend, :sum, 0) { |total, weight| total + weight }.collected
end

def sorted(person)
  groups2(person).v.where('sum != nil')[[:sum, :friend]].sort
end

def groups3(person)
  person.in(:rated).out(:rated).is_not(person).uniq.group.values_route(:default) do |friend| 
      friend.in_e(:rated).as(:fre).out_v.out_e.as(:mre).in_v.is(person).map do |v|
        5 - (v.vars[:fre][:weight] - v.vars[:mre][:weight]).abs
      end
  end.reduce(0) { |total, n| total + n }
end

def groups5(person)
  mg = person.in(:rated).out(:rated).is_not(person).uniq.
    join(:ratings) do |friend|
      friend.in_e(:rated).as(:fre).out_v.out_e.as(:mre).in_v.is(person).map do |v|
        5 - (v.vars[:fre][:weight] - v.vars[:mre][:weight]).abs
      end
    end.
    join(:friend) { |f| f }.
    join(:person) { person }.
    join(:rated) { |friend| friend.in_e(:rated).out_v.lookahead { |v| v.out_e.in_v.is(person) } }.
    join(:friend_ratings) { |friend| friend.in_e(:rated).lookahead { |e| e.out_v.out.is(person) }[:weight].paths }.
    join(:person_ratings) { |friend| friend.in(:rated).out_e.lookahead { |e| e.in_v.is(person) }[:weight].paths }.
    multigraph
  mg.v.each { |v| v[:sum] = v[:ratings].inject(:+) }
  mg
end

def groups4(person)
  graph = person.v.
    in(:rated).out(:rated).is_not(person).uniq.collect_as(:friend).
      in_e(:rated).as(:fre).out_v.out_e.as(:mre).in_v.is(person).map_to(:friend, :ratings) do |v, _| 
        5 - (v.vars[:fre][:weight] - v.vars[:mre][:weight]).abs
      end.
    collected
  graph.v.each { |v| v[:sum] = v[:ratings].inject(:+) }
  graph
end

