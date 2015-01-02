package com.xnlogic.pacer.pipes;

import static org.junit.Assert.*;
import org.junit.Test;
import java.util.Collection;
import java.util.Arrays;
import com.xnlogic.pacer.pipes.IsUniquePipe;

public class IsUniquePipeTest {

    @Test
    public void allUniqueTest() {
        Collection<String> collection = Arrays.asList("These", "are", "all", "unique");
        IsUniquePipe<String> isUniquePipe = new IsUniquePipe<String>();

        isUniquePipe.setStarts(collection);

        String s = isUniquePipe.next();
        assertTrue(s.equals("These"));
        assertTrue(isUniquePipe.isUnique());
        
        s = isUniquePipe.next();
        assertTrue(s.equals("are"));
        assertTrue(isUniquePipe.isUnique());
        
        s = isUniquePipe.next();
        assertTrue(s.equals("all"));
        assertTrue(isUniquePipe.isUnique());
        
        s = isUniquePipe.next();
        assertTrue(s.equals("unique"));
        assertTrue(isUniquePipe.isUnique());
    }
    
    @Test
    public void notAllUniqueTest() {
        Collection<String> collection = Arrays.asList("Not", "all", "all", "all", "unique");
        IsUniquePipe<String> isUniquePipe = new IsUniquePipe<String>();

        isUniquePipe.setStarts(collection);

        String s = isUniquePipe.next();
        assertTrue(s.equals("Not"));
        assertTrue(isUniquePipe.isUnique());
        
        s = isUniquePipe.next();
        assertTrue(s.equals("all"));
        assertTrue(isUniquePipe.isUnique());
        
        s = isUniquePipe.next();
        assertTrue(s.equals("all"));
        assertFalse(isUniquePipe.isUnique());
        
        s = isUniquePipe.next();
        assertTrue(s.equals("all"));
        assertFalse(isUniquePipe.isUnique());
        
        s = isUniquePipe.next();
        assertTrue(s.equals("unique"));
        assertFalse(isUniquePipe.isUnique());
    }
}
