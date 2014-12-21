package com.xnlogic.pacer.pipes;

import com.tinkerpop.pipes.AbstractPipe;


public class BlockFilterPipe<T> extends AbstractPipe<T, T> {
    private boolean invert;

    // TODO: Figure out if this is using Java 7 or 8 as Java 7 doesn't support lambdas/blocks.
    /*
    public BlockFilterPipe(back, block, boolean invert) {
        super();

        this.invert = invert;
        this.block = ;
    }

    public BlockFilterPipe(back, block) {
        this(back, block, false);
    }
*/
    protected T processNextStart() {
        return this.starts.next();    
    }
}
