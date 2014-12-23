package com.xnlogic.pacer.pipes;

import com.tinkerpop.pipes.AbstractPipe;
import com.tinkerpop.blueprints.Edge;
import java.util.Set;
import java.util.Collection;
import java.util.HashSet;
import java.util.Arrays;

public class LabelCollectionFilterPipe extends AbstractPipe<Edge, Edge> {
    private Set<String> labels;

    public LabelCollectionFilterPipe(Collection<String> labels) {
        if (labels instanceof Set) {
            this.labels = (Set)labels;
        } else if (labels == null) {
            this.labels = new HashSet();
        } else {
            this.labels = new HashSet();
            this.labels.addAll(labels);
        }
    }

    protected Edge processNextStart() {
        while (true) {
            Edge edge = this.starts.next();
            if (edge != null && this.labels.contains(edge.getLabel())) {
                return edge;
            }
        }
    }
}
