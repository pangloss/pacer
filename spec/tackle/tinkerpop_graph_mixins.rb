module TP
  module Person
    def self.route_conditions
      { :type => 'person' }
    end

    module Route
      def projects
        out_e.in_v(Project)
      end
    end
  end


  class Project
    def self.route_conditions
      { :type => 'project' }
    end

    module Route
      def people
        in_e.out_v(Person)
      end
    end
  end

  class Pangloss
    def self.route(base)
      base.v(:name => 'pangloss')
    end
  end

  module Coder
    module Route
      def projects
        out(Project, Software)
      end
    end
  end

  module Software
    module Route
      def coders
        self.in(Coder)
      end
    end
  end

  module Wrote
    def self.route_conditions
      { label: 'wrote' }
    end

    module Edge
      def writer
        out_vertex
      end
    end
  end
end
