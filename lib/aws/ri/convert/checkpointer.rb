require 'yaml'

module Aws::Ri::Convert
  class Checkpointer
    SUFFIX = ".save"

    def initialize(cpdir)
      @cpdir = cpdir
    end

    def load(name)
      cps = Dir[File.join(@cpdir, "*")].select{|f|
        File.basename(f) =~ /\A#{name}\..*#{SUFFIX}\Z/
      }

      if cps.empty?
        return {}
      end

      load_file = cps.sort.last

      YAML.load(File.read(load_file))
    end

    def save(name, state)
      FileUtils.mkdir_p(@cpdir)

      now = Time.now.to_i

      File.write(File.join(@cpdir, "#{name}.#{now}#{SUFFIX}"), YAML.dump(state))
    end
  end
end
