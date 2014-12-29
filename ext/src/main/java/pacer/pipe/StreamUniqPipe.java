package com.xnlogic.pacer.pipes;

import com.tinkerpop.pipes.AbstractPipe;
import java.util.LinkedList;

public class StreamUniqPipe<T> extends AbstractPipe<T, T> {
    private LinkedList list;
    private int buffer;
    
    public StreamUniqPipe(final int buffer) {
        super();
        this.list = new LinkedList();
        this.buffer = buffer;
    }

    public StreamUniqPipe() {
        this(1000);
    }

    protected T processNextStart() {
        while (true) {
            T obj = this.starts.next();
            boolean duplicate = this.list.removeLastOccurrence(obj);
            this.list.addLast(obj);

            if (!duplicate) {
                if (this.buffer == 0)
                    this.list.removeFirst();
                else
                    this.buffer--;

                return obj;
            }
        }
    }
}
