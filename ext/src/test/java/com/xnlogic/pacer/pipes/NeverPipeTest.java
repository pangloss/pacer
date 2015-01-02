package com.xnlogic.pacer.pipes;

import java.util.ArrayList;
import java.util.NoSuchElementException;

import org.junit.Test;

public class NeverPipeTest {
    @Test(expected=NoSuchElementException.class)
    public void ensureExceptionTest() {
        NeverPipe neverPipe = new NeverPipe();
        ArrayList<Object> starts = new ArrayList<Object>();
        starts.add(new Object());
        neverPipe.setStarts(starts.iterator());
        neverPipe.next();
    }
}
