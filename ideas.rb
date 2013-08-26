g.v.parallel(threads: 8, in_buffer: 4, out_buffer: 10) { |v| v.out.out.out.out.out }

# - eagerly consume (1) input and push into a channel
#   - ChannelCapPipe
#   - create a cap pipe that does this. The pipe's output is the channel
#   - source data may be slow. Should probably not use a go block
#   - 1 thread in a loop
# - Control the construction of parallel pipes. Default 2 threads, make
# it configurable.
#   - standard copy split pipe can push the channel to subchannels
#   - each parallel route pulls from the channel.
#     - in a go block (waits will not block go thread pool)
#     - ChannelReaderPipe
#     - PathChannelReaderPipe
#   - parallel routes are unmodified
#   - cap each route - eagerly consume input and push into a channel
#     - ChannelCapPipe again
#   -
#     - like ExhaustMergePipe + GatherPipe
# - use alts to read from any of the channels
# - ChannelAltsReaderPipe



# CCP
# CSP (parallelism is 1 thread per pipe being split into)
#   CRP -> Work ... -> CCP
#   CRP -> Work ... -> CCP
#   ...
# EMP
# GP
# CARP
