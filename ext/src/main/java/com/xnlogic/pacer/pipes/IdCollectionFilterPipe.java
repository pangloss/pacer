package com.xnlogic.pacer.pipes;

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;

import com.tinkerpop.blueprints.Contains;
import com.tinkerpop.blueprints.Element;
import com.tinkerpop.pipes.AbstractPipe;

public class IdCollectionFilterPipe<E extends Element> extends AbstractPipe<E, E> {
    private Set ids;
    private boolean containsIn;
    
    // TODO: Consider making this a derived exception.  Also, this constructor is the reverse of the Ruby one. Is this ok?
    // Also also, is an Object array the way to go?  Can we nail down the type further?
    public IdCollectionFilterPipe(final Collection ids, final Contains comparison) throws RuntimeException {
        super();
        if (ids instanceof Set) {
            this.ids = (Set)ids;
        } else if (ids == null) {
            this.ids = new HashSet();
        } else {
            this.ids = new HashSet();
            this.ids.addAll(ids);
        }
        if (comparison == Contains.IN)
            this.containsIn = true;
        else if (comparison == Contains.NOT_IN)
            this.containsIn = false;
        else
            throw new RuntimeException("Unknown comparison type for ID collection filter");
    }

    protected E processNextStart() {
        if (this.containsIn) {
            while (true) {
                E e = this.starts.next();
                if (e != null && this.ids.contains(e.getId())) 
                    return e;
            }
        } else {
            while (true) {
                E e = this.starts.next();
                if (e != null && !this.ids.contains(e.getId()))
                    return e;
            }
        }
    }
}
