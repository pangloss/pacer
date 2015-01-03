package com.xnlogic.pacer.pipes;

import com.tinkerpop.blueprints.Edge;
import com.tinkerpop.pipes.AbstractPipe;
import java.util.regex.Pattern;

public class LabelPrefixPipe extends AbstractPipe<Edge, Edge> {
    private Pattern pattern;
  
    public LabelPrefixPipe(final String pattern) {
        super();
        this.pattern = Pattern.compile("^" + pattern);
    }

    protected Edge processNextStart() {
        while (true) {
            Edge e = this.starts.next();
            if (this.pattern.matcher(e.getLabel()).matches()) {
                return e;
            }
        }
    }
}
