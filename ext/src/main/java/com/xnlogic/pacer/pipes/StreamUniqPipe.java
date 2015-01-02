package com.xnlogic.pacer.pipes;

import java.util.HashSet;
import java.util.Set;

import com.tinkerpop.pipes.AbstractPipe;

public class StreamUniqPipe<T> extends AbstractPipe<T, T> {
	
	public static final int DEFAULT_BUFFER_CAPACITY = 1000;
	
    private Set<T> buffer;
    private int bufferCapacity;
    
    public StreamUniqPipe(final int bufferCapacity) {
        super();
        this.buffer = new HashSet<T>();
        this.bufferCapacity = bufferCapacity;
    }

    public StreamUniqPipe() {
        this(DEFAULT_BUFFER_CAPACITY);
    }

    protected T processNextStart() {
        while (true) {
            T obj = this.starts.next();
            
            if(! buffer.contains(obj)){
            	if(buffer.size() < bufferCapacity){
            		buffer.add(obj);
            	}
            	
            	return obj;
            }
        }
    }
}
