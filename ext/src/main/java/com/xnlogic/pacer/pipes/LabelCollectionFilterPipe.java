package com.xnlogic.pacer.pipes;

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;

import com.tinkerpop.blueprints.Edge;
import com.tinkerpop.pipes.AbstractPipe;

public class LabelCollectionFilterPipe extends AbstractPipe<Edge, Edge> {
    private Set<String> labels;

    public LabelCollectionFilterPipe(final Collection<String> labels) {
        if (labels instanceof Set) {
            this.labels = (Set<String>)labels;
        } else {
        	this.labels = new HashSet<String>();
        	if(labels != null){
        		this.labels.addAll(labels);
        	}
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
