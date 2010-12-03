To Test:
  - exhaustive merge should not filter the edges out of the results below:
      >> g = Pacer.neo4j '/Users/dw/dev/ucmdb/tmp/neo.db'
      => #<Neo4jGraph>
      >> g.v(:type => 'nt').out_e { |e| e.label != 'contained' }.branch { |b| b.out_v }.branch { |b| b.in_v.in_e }
      #<V[100]>                        #<E[99777]:1439-dependency-3363> #<V[133]>
      #<E[99757]:2352-dependency-3363> #<V[255]>                        #<E[99747]:484-dependency-3363>
      #<V[267]>                        #<E[99734]:6055-dependency-3363> #<V[296]>
      #<E[99728]:5686-dependency-3363> #<V[316]>                        #<E[99727]:4400-dependency-3363>
      #<V[341]>                        #<E[99715]:5319-dependency-3363> #<V[368]>
      #<E[99711]:100-dependency-3363>  #<V[379]>                        #<E[99699]:6625-dependency-3363>
      #<V[389]>                        #<E[99696]:3282-dependency-3363> #<V[404]>
      #<E[99680]:5104-dependency-3363> #<V[406]>                        #<E[99630]:133-dependency-3363>
      #<V[1730]>                       #<E[99615]:1933-dependency-3363> #<V[2471]>
      #<E[99598]:2648-dependency-3363> #<V[2471]>                       #<E[99577]:5753-dependency-3363>
      #<V[2959]>                       #<E[99568]:1730-dependency-3363>
      Total: 32
      => #<Vertices([{:type=>"nt"}]) -> Edges(OUT_EDGES, &block) -> Branched { #<E -> Vertices(OUT_VERTEX)> | #<E -> Vertices(IN_VERTEX) -> Edges(IN_EDGES)> }>
      >> g.v(:type => 'nt').out_e { |e| e.label != 'contained' }.branch { |b| b.out_v }.branch { |b| b.in_v.in_e }.exhaustive
      #<V[100]>  #<V[133]>  #<V[255]>  #<V[267]>  #<V[296]>  #<V[316]>  #<V[341]>  #<V[368]>  #<V[379]>  #<V[389]>
      #<V[404]>  #<V[406]>  #<V[1730]> #<V[2471]> #<V[2471]> #<V[2959]>
      Total: 16
      => #<Vertices([{:type=>"nt"}]) -> Edges(OUT_EDGES, &block) -> Branched { #<E -> Vertices(OUT_VERTEX)> | #<E -> Vertices(IN_VERTEX) -> Edges(IN_EDGES)> }>

To do:
  - Mixed#as needs a mixed variable path defined
