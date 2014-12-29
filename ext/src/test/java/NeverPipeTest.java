package com.xnlogic.pacer.pipes;

import static org.junit.Assert.*;
import org.junit.Test;
import com.xnlogic.pacer.pipes.NeverPipe;
import java.util.ArrayList;
import java.util.NoSuchElementException;

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
