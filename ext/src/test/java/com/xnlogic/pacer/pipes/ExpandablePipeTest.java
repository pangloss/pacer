package com.xnlogic.pacer.pipes;

import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.util.ArrayList;

import org.junit.Test;

public class ExpandablePipeTest {

    @Test
    public void queueWithElementsTest() {
        ExpandablePipe<String> expandablePipe = new ExpandablePipe<String>();

        ArrayList<String> input = new ArrayList<String>();
        input.add("X");

        expandablePipe.setStarts(input.iterator());

        expandablePipe.add("a", 1, new ArrayList<Object>());
        expandablePipe.add("b", 2, new ArrayList<Object>());
        expandablePipe.add("c", 3, new ArrayList<Object>());
      
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
