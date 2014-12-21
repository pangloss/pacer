package com.xnlogic.pacer.pipes;

import com.tinkerpop.pipes.AbstractPipe;
import com.tinkerpop.pipes.sideeffect.SideEffectPipe;
import com.tinkerpop.pipes.util.iterators.ExpandableIterator;
import com.tinkerpop.pipes.filter.DuplicateFilterPipe;
import com.tinkerpop.pipes.util.FastNoSuchElementException;
import java.util.ArrayList;
import java.util.NoSuchElementException;

// TODO: Discuss "Boolean" choice for pipe here with dw.  Especially as it speaks directly to the use case and unit tests.
public class IsEmptyPipe extends AbstractPipe<Boolean, Boolean> {
    private boolean raise;  
  
    public IsEmptyPipe() {
        super();
        this.raise = false;
    }

    protected Boolean processNextStart() throws NoSuchElementException{
        if (this.raise) {
            throw FastNoSuchElementException.instance();
        }

        try {
            this.starts.next();
            this.raise = true;
        } catch (NoSuchElementException nsee) {
            return true;
        }

        throw FastNoSuchElementException.instance();
    }

    public void reset() {
        this.raise = false;
        super.reset();
    }
}
