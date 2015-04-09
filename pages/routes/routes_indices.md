---
title: Indicaes
permalink: /routes-indices/
---

Most graph traversals will start from an index. Pacer makes indices easy to work with by **auto-selecting the best available index**. Most of the time you
simply do not need to think about indices.

## Creating auto indices

Indices can be created using `create_key_index` for either vertices or edges. By default, all indices are at the scope of the entire graph, though there may be the possibility
of using other strategies in vendor-specific code. Indices will be built when created, so this call can take a significant amount of time on a large
graph.

Usage:

- `graph.create_key_index(:property_name)` By default, vertex indices are created.
- `graph.create_key_index(:property_name, :vertex, opts_hash)` Explicitly creating vertex index with implementation-specific options passed through
- `graph.create_key_index(:property_name, :edge)` Create an edge index

## Dropping auto indices

Usage:

- `graph.drop_auto_index(:property_name, :vertex)`
- `graph.drop_auto_index(:property_name, :edge)`
