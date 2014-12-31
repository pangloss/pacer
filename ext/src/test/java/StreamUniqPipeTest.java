package com.xnlogic.pacer.pipes;

import static org.junit.Assert.*;
import org.junit.Test;
import java.util.List;
import java.util.ArrayList;
import com.xnlogic.pacer.pipes.StreamUniqPipe;

public class StreamUniqPipeTest {

    private List<Integer> createUniqueIntegers(final int total) {
        List<Integer> list = new ArrayList<Integer>();
      
        for (int i = 0; i < total; i++)
            list.add(new Integer(i));

        return list;
    }
    
    private List<Integer> createSameInteger(final int number, final int total) {
        List<Integer> list = new ArrayList<Integer>();
      
        for (int i = 0; i < total; i++)
            list.add(new Integer(number));

        return list;
    }
    
    @Test
    public void allUniqueLargerBufferThanStartsTest() {
        List<Integer> list = this.createUniqueIntegers(10);
        StreamUniqPipe<Integer> streamUniqPipe = new StreamUniqPipe<Integer>();
        streamUniqPipe.setStarts(list.iterator());

        int count = 0;

        while (streamUniqPipe.hasNext()) {
            count++;
            streamUniqPipe.next();
        }

        assertEquals(10, count);
    }
    
    @Test
    public void allUniqueSmallerBufferThanStartsTest() {
        List<Integer> list = this.createUniqueIntegers(50);
        StreamUniqPipe<Integer> streamUniqPipe = new StreamUniqPipe<Integer>(10);
        streamUniqPipe.setStarts(list.iterator());

        int count = 0;

        while (streamUniqPipe.hasNext()) {
            count++;
            streamUniqPipe.next();
        }

        assertEquals(50, count);
    }

    @Test
    public void allDuplicatesTest() {
        List<Integer> list = this.createSameInteger(1, 10);
        StreamUniqPipe<Integer> streamUniqPipe = new StreamUniqPipe<Integer>();
        streamUniqPipe.setStarts(list.iterator());

        int count = 0;

        while (streamUniqPipe.hasNext()) {
            count++;
            streamUniqPipe.next();
        }

        assertEquals(1, count);
    }

    @Test
    public void uniqueAndDuplicateSplitTest() {
        List<Integer> list = this.createSameInteger(100, 50);
        List<Integer> list2 = this.createUniqueIntegers(50);
        list.addAll(list2);
        StreamUniqPipe<Integer> streamUniqPipe = new StreamUniqPipe<Integer>();
        streamUniqPipe.setStarts(list.iterator());

        int count = 0;

        while (streamUniqPipe.hasNext()) {
            count++;
            streamUniqPipe.next();
        }

        assertEquals(51, count);
    }
    
    @Test
    public void ensureReturnFromDuplicatesTest() {
        List<Integer> list = this.createSameInteger(1, 10);
        StreamUniqPipe<Integer> streamUniqPipe = new StreamUniqPipe<Integer>();
        streamUniqPipe.setStarts(list.iterator());

        List<Integer> filteredList = new ArrayList<Integer>();

        while (streamUniqPipe.hasNext()) {
            filteredList.add(streamUniqPipe.next());
        }

        assertEquals(1, filteredList.size());
        assertEquals((Integer)filteredList.get(0), new Integer(1));
    }
    
    @Test
    public void ensureReturnFromUniquesTest() {
        List<Integer> list = this.createUniqueIntegers(3);
        StreamUniqPipe<Integer> streamUniqPipe = new StreamUniqPipe<Integer>();
        streamUniqPipe.setStarts(list.iterator());

        List<Integer> filteredList = new ArrayList<Integer>();

        while (streamUniqPipe.hasNext()) {
            filteredList.add(streamUniqPipe.next());
        }

        assertEquals(3, filteredList.size());

        assertEquals((Integer)filteredList.get(0), new Integer(0));
        assertEquals((Integer)filteredList.get(1), new Integer(1));
        assertEquals((Integer)filteredList.get(2), new Integer(2));
    }
}
