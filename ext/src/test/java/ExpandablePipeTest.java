package com.xnlogic.pacer.pipes;

import static org.junit.Assert.*;
import org.junit.Test;
import java.util.Arrays;
import com.tinkerpop.pipes.Pipe;
import com.tinkerpop.pipes.IdentityPipe;
import com.tinkerpop.pipes.AbstractPipe;
import java.util.Iterator;
import com.xnlogic.pacer.pipes.ExpandablePipe;

public class ExpandablePipeTest {

    @Test
    public void queueWithElementsTest() {
        ExpandablePipe expandablePipe = new ExpandablePipe();

        IdentityPipe<Pipe> pipe1 = new IdentityPipe<Pipe>();
        IdentityPipe<Pipe> pipe2 = new IdentityPipe<Pipe>();
        IdentityPipe<Pipe> pipe3 = new IdentityPipe<Pipe>();
        IdentityPipe<Pipe> pipe4 = new IdentityPipe<Pipe>();
        DeadPipe pipe5 = new DeadPipe();
       
        pipe1.enablePath(true);
        pipe2.enablePath(true);
        pipe3.enablePath(true);
        pipe4.enablePath(true);
        
        expandablePipe.add(pipe1, 1, pipe1.getCurrentPath());
        expandablePipe.add(pipe2, 2, pipe2.getCurrentPath());
        expandablePipe.add(pipe3, 3, pipe3.getCurrentPath());
      
        pipe4.setStarts(pipe5);
        expandablePipe.setStarts(pipe4);
        
        Pipe p = expandablePipe.next();
        assertTrue(pipe1.equals(p));
        assertTrue(expandablePipe.getMetadata().equals(1));

        p = expandablePipe.next();
        assertTrue(pipe2.equals(p));
        assertTrue(expandablePipe.getMetadata().equals(2));
        
        p = expandablePipe.next();
        assertTrue(pipe3.equals(p));
        assertTrue(expandablePipe.getMetadata().equals(3));
        
        p = expandablePipe.next();
        assertTrue(pipe5.equals(p));
        assertNull(expandablePipe.getMetadata());
    }

    @Test
    public void emptyQueueTest() {
        ExpandablePipe expandablePipe = new ExpandablePipe();

        IdentityPipe<Pipe> pipe1 = new IdentityPipe<Pipe>();
        DeadPipe pipe2 = new DeadPipe();
       
        pipe1.enablePath(true);

        pipe1.setStarts(pipe2);
        expandablePipe.setStarts(pipe1);
        
        Pipe p = expandablePipe.next();
        assertTrue(pipe2.equals(p));
        assertNull(expandablePipe.getMetadata());
    }

    // TODO: Test getPathToHere() ?

    private class DeadPipe extends AbstractPipe<Pipe, Pipe> {
        protected Pipe processNextStart() {
            return this;
        }
    }
      
}
