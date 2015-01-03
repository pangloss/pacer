package com.xnlogic.pacer.pipes;

import static org.junit.Assert.*;
import org.junit.Test;
import com.tinkerpop.pipes.Pipe;
import com.tinkerpop.pipes.IdentityPipe;
import java.util.Arrays;
import java.util.List;
import com.xnlogic.pacer.pipes.BlackboxPipeline;

public class BlackboxPipelineTest {
    @Test
    public void resetTest() {
        List<String> data = Arrays.asList("Pacer", "Pipes", "Test");
        Pipe<String, String> pipe1 = new IdentityPipe<String>();
        Pipe<String, String> pipe2 = new IdentityPipe<String>();
        BlackboxPipeline<String, String> blackboxPipeline = new BlackboxPipeline<String, String>(pipe1, pipe2);

        blackboxPipeline.setStarts(data);
        pipe2.setStarts(data);
        
        int count = 0;
        
        while (blackboxPipeline.hasNext()) {
            assertEquals(blackboxPipeline.next(), data.get(count));
            blackboxPipeline.reset();
            count++;
        }

        assertEquals(count, data.size());
        assertFalse(blackboxPipeline.hasNext());
    }
}
