
class Array
  PipesPipe = com.tinkerpop.pipes.Pipe
  unless instance_methods.include? :plus_without_multi
    alias plus_without_multi +
    def +(other)
      plus_with_multi(other)
    end
  end

  def plus_with_multi(other)
    if other.is_a? PipesPipe or other.is_a? Enumerator
      Pacer::Pipes::MultiPipe.new [self, other]
    else
      plus_without_multi(other)
    end
  end
end
