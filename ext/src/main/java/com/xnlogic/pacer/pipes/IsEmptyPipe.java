package com.xnlogic.pacer.pipes;

import java.util.NoSuchElementException;

import com.tinkerpop.pipes.AbstractPipe;
import com.tinkerpop.pipes.util.FastNoSuchElementException;

public class IsEmptyPipe<T> extends AbstractPipe<T, Boolean> {
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
