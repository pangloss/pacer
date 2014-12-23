package com.xnlogic.pacer.pipes;

import static org.junit.Assert.*;
import org.junit.Test;
import java.util.Arrays;
import java.util.ArrayList;
import com.tinkerpop.pipes.Pipe;
import com.tinkerpop.pipes.IdentityPipe;
import com.tinkerpop.pipes.AbstractPipe;
import java.util.Iterator;
import com.xnlogic.pacer.pipes.ExpandablePipe;

public class ExpandablePipeTest {

    @Test
    public void queueWithElementsTest() {
        ExpandablePipe expandablePipe = new ExpandablePipe();

        ArrayList input = new ArrayList();
        input.add("X");

        expandablePipe.setStarts(input.iterator());

        expandablePipe.add("a", 1, new ArrayList());
        expandablePipe.add("b", 2, new ArrayList());
        expandablePipe.add("c", 3, new ArrayList());
      
        Object result = expandablePipe.next();
        assertTrue(result.equals("a"));
        assertTrue(expandablePipe.getMetadata().equals(1));

        result = expandablePipe.next();
        assertTrue(result.equals("b"));
        assertTrue(expandablePipe.getMetadata().equals(2));
        
        result = expandablePipe.next();
        assertTrue(result.equals("c"));
        assertTrue(expandablePipe.getMetadata().equals(3));
        
        result = expandablePipe.next();
        assertTrue(result.equals("X"));
        assertNull(expandablePipe.getMetadata());
    }

    @Test
    public void emptyQueueTest() {
        // TODO: fix this test

        //ExpandablePipe expandablePipe = new ExpandablePipe();

        //IdentityPipe<Pipe> pipe1 = new IdentityPipe<Pipe>();
        //DeadPipe pipe2 = new DeadPipe();
       
        //pipe1.enablePath(true);

        //pipe1.setStarts(pipe2);
        //expandablePipe.setStarts(pipe1);
        //
        //Pipe p = expandablePipe.next();
        //assertTrue(pipe2.equals(p));
        //assertNull(expandablePipe.getMetadata());
    }

    // TODO: Test getPathToHere()
      
}
