require 'optparse'
require 'fileutils'

# = lib/annotation_security/exec.rb
# This file is borrowed heavily from HAML
#

module AnnotationSecurity
  module Exec # :nodoc:

    # An abstract class that encapsulates the executable
    # code for all executables.
    class Generic # :nodoc:

      # Parsed options
      def options
        @options ||= {}
      end

      # @param args [Array<String>] The command-line arguments
      def initialize(args)
        @args = args
      end
      
      # Parses the command-line arguments and runs the executable.
      # Calls `Kernel#exit` at the end, so it never returns.
      def parse!
        begin
          @opts = OptionParser.new(&method(:set_opts))
          @opts.parse!(@args)

          process_result

          options
        rescue Exception => e
          raise e if e.is_a?(SystemExit) || options[:trace]

          $stderr.puts e.message
          exit 1
        end
        exit 0
      end

      # @return [String] A description of the executable
      def to_s
        @opts.to_s
      end

      protected

      # Tells optparse how to parse the arguments
      # available for all executables.
      #
      # This is meant to be overridden by subclasses
      # so they can add their own options.
      #
      # @param opts [OptionParser]
      def set_opts(opts)
        opts.on("--force", "Force command execution, override assets without asking") do
          options[:force] = true
        end

        opts.on("--trace", "Shows full stack trace in case of errors") do
          options[:trace] = true
        end

        opts.on_tail("-?", "-h", "--help", "Show this message") do
          puts opts
          exit
        end

        opts.on_tail("-v", "--version", "Print version") do
          puts("AnnotationSecurity 0.01")
          exit
        end
      end

      # Processes the options set by the command-line arguments.
      # 
      # This is meant to be overridden by subclasses
      # so they can run their respective programs.
      def process_result; end
    end

    # An abstrac class that encapsulates the code
    # specific to executables.
    class RailsInstaller < Generic # :nodoc:

      ASSET_FILES = %w{
        config/initializers/annotation_security.rb
        config/security/relations.rb
        config/security/rights.yml
        app/helpers/annotation_security_helper.rb
        vendor/plugins/annotation_security/init.rb
      }
      
      # @param args [Array<String>] The command-line arguments
      def initialize(args)
        super
        @name = "annosec"
      end

      protected

      # Tells optparse how to parse the arguments.
      #
      # This is meant to be overridden by subclasses
      # so they can add their own options.
      #
      # @param opts [OptionParser]
      def set_opts(opts)
        opts.banner = <<END
Usage: #{@name.downcase} [options]

Description:
  Installs the AnnotationSecurity layer into a rails app

Options:
END
        
        opts.on('--rails RAILS_DIR', "Install AnnotationSecurity layer from the Gem to a Rails project") do |dir|
          options[:rails_dir] = dir
        end

        super
      end

      # Processes the options set by the command-line arguments.
      # In particular, sets `@options[:for_engine][:filename]` to the input filename
      # and requires the appropriate file.
      #
      # This is meant to be overridden by subclasses
      # so they can run their respective programs.
      def process_result

        unless options[:rails_dir]
          puts @opts
          exit
        end

        options[:cur_dir] = File.dirname(__FILE__)
        options[:assets_dir] = File.join(options[:cur_dir], '..', '..', 'assets')

        assert_exists('config')
        assert_exists('vendor')
        assert_exists('app/helpers')

        ASSET_FILES.each { |f| install_file(f) }

        puts "AnnotationSecurity plugin added to #{options[:rails_dir]}"
        exit
      end

      private
      
      def assert_exists(dir)
        dir = File.join(options[:rails_dir], dir)
        unless File.exists?(dir)
          if options[:force]
            puts "Creating #{dir}"
            FileUtils.mkdir_p dir
          else
            puts "Directory #{dir} does not exist"
            exit
          end
        end
      end
      
      def install_file(f)
        orign = File.join(options[:assets_dir], f)
        dest = File.join(options[:rails_dir], f)
        
        if File.exists?(dest) && !options[:force]
          print "File #{dest} already exists, overwrite [y/N]? "
          return if gets !~ /y/i
        end

        dir = File.dirname(dest)
        unless File.exists?(dir)
          puts "Creating #{dir}"
          FileUtils.mkdir_p(dir)
        end
        
        FileUtils.install(orign, dest)
        puts "Installed #{dest}"
      end
    end
  end
end