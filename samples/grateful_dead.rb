module GD
  module Artist
    def self.route_conditions
      { type: 'artist' }
    end

    module Route
      def written
        in_e(:written_by).out_v(Song)
      end

      def sung
        in_e(:sung_by).out_v(Song)
      end

      def songwriters
        lookahead { |v| v.in_e(:written_by) }
      end

      def singers
        lookahead { |v| v.in_e(:sung_by) }
      end
    end
  end

  module Song
    def self.route_conditions
      { type: 'song' }
    end

    module Route
      def writer(*args)
        out_e(:written_by).in_v(Artist).filter(*args)
      end

      def sung(*args)
        out_e(:sung_by).in_v(Artist).filter(*args)
      end

      def next_song(arg = nil, args = nil)
        if arg.is_a? Fixnum
          out_e(:followed_by, :weight => arg).in_v(Song).filter(args)
        else
          out_e(:followed_by).in_v(Song).filter(arg)
        end
      end

      def prev_song(arg = nil, args = nil)
        if arg.is_a? Fixnum
          in_e(:followed_by, :weight => arg).out_v(Song).filter(args)
        else
          in_e(:followed_by).out_v(Song).filter(arg)
        end
      end

      def collaborations
        # The [1] is a range filter. It will only succeed if there are
        # at least 2 results (remember, range filter is 0-indexed)
        lookahead { |s| s.writer.uniq[1] }
      end
    end
  end
end
