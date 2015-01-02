package com.xnlogic.pacer.pipes;

import com.tinkerpop.pipes.AbstractPipe;
import com.tinkerpop.pipes.util.FastNoSuchElementException;

public class NeverPipe extends AbstractPipe<Object, Object> {
    protected Object processNextStart() {
        throw FastNoSuchElementException.instance();
    }
}
