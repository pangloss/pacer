package com.xnlogic.pacer.pipes;

import static org.junit.Assert.*;
import org.junit.Test;
import com.tinkerpop.blueprints.Contains;
import java.util.Collection;
import java.util.Arrays;
import java.util.ArrayList;
import com.xnlogic.pacer.pipes.CollectionFilterPipe;

public class CollectionFilterPipeTest {
    @Test
    public void filterInTest() {
        Collection<String> collection = Arrays.asList("Pacer", "Pipes", "XNLogic");
        Collection<String> starts = Arrays.asList("Pacer", "XNLogic");
        Collection<String> result = new ArrayList<String>();
        CollectionFilterPipe<String> collectionFilterPipe = new CollectionFilterPipe<String>(collection, Contains.IN);

        collectionFilterPipe.setStarts(starts);

        while (collectionFilterPipe.hasNext()) {
            result.add(collectionFilterPipe.next());
        }

        assertEquals(2, result.size());
        assertTrue(result.contains("Pacer"));
        assertTrue(result.contains("XNLogic"));
        assertFalse(result.contains("Pipes"));
    }

    @Test
    public void filterNotInTest() {
        Collection<String> collection = Arrays.asList("Pacer", "Pipes", "XNLogic");
        Collection<String> starts = Arrays.asList("Pacer", "Java");
        Collection<String> result = new ArrayList<String>();
        CollectionFilterPipe<String> collectionFilterPipe = new CollectionFilterPipe<String>(collection, Contains.NOT_IN);

        collectionFilterPipe.setStarts(starts);

        while (collectionFilterPipe.hasNext()) {
            result.add(collectionFilterPipe.next());
        }

        assertEquals(1, result.size());
        assertFalse(result.contains("Pacer"));
        assertTrue(result.contains("Java"));
    }

    // TODO: Test other constructor version.
}
