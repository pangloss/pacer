package com.xnlogic.pacer.pipes;

import com.tinkerpop.blueprints.Contains;
import com.tinkerpop.pipes.util.structures.AsMap;

import java.util.Collection;

public class CollectionFilterPipe<S> extends com.tinkerpop.pipes.filter.CollectionFilterPipe<S> {

    public CollectionFilterPipe(final Collection<S> storedCollection, final Contains contains) {
        super(storedCollection, contains);
    }

    public CollectionFilterPipe(final Contains contains, final AsMap asMap, final String... namedSteps) {
        super(contains, asMap, namedSteps);
    }

}
