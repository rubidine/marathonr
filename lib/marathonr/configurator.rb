# Copyright (c) 2008 Todd Willey <todd@rubidine.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'yaml'
require 'optparse'

module Marathonr

  ##
  # The Configurator merges command line arguments, defaults, and config file
  # options into a single configuration that is the authoratative source.
  #
  # Call Configurator.configure to get the Configuration.
  class Configurator
    def self.configure
      @configuration = Configuration.new(
        :supress_current_directory_configuration => false,
        :adapter => 'mysql',
        :username => 'root',
        :password => '',
        :database => 'marathonr',
        :table_name => nil,
        :worker_dir => 'workers',
        :poll_interval => 0.25,
        :max_workers => 10,
        :worker_timeout => 600
      )
      load_configuration
      set_table_name
      @configuration
    end

    private

    def self.load_configuration
      load_configuration_from_arguments
      unless @configuration[:supress_current_directory_configuration]
        load_configuration_from_working_directory
      end
    end

    def self.load_configuration_from_arguments
      OptionParser.new do |opts|
        opts.on('-c', '--config-file FILE', 'Load configuration from FILE') do |c|
          if !File.exist?(f) or !File.readable(f)
            raise IOError, "Unable to read #{f}"
          end
          load_configuration_file(f)
        end

        opts.on('-x', '--ignore-current-dir-config', 'Ignore configuration files in the current directory') do
          @configuration[:supress_current_directory_configuration] = true
        end

        opts.on('-s', '--sql-server SQL', 'Use SQL adapter') do |s|
          @configuration[:adapter] = s
        end

        opts.on('-w', '--password PASS', 'Use PASS to talk to database') do |w|
          @configuration[:password] = w
        end

        opts.on('-u', '--usernmae USER', 'Use USER to talk to database') do |u|
          @configuration[:username] = u
        end

        opts.on('-d', '--database DB', 'Use database DB') do |d|
          @configuration[:database] = d
        end

        opts.on('-t', '--table TABLE', 'Use database table TABLE for WorkRequest') do |t|
          @configuration[:table_name] = t
        end

        opts.on('-r', '--worker-dir DIR', 'Load worker classes from DIR') do |r|
          @configuration[:worker_dir] = r
        end

        opts.on('-i', '--poll-interval TIME', 'Check for new work in TIME') do |i|
          @configuration[:poll_interval] = i.to_f
        end

        opts.on('-n', '--num-workers NUM', 'Only fork upto NUM workers') do |n|
          @configuration[:max_workers] = m.to_i
        end

        opts.on('-m', '--max-execution-time TIME', 'Workers can only run for TIME seconds befroe being killed') do |m|
          @configuration[:worker_timeout] = m.to_i
         end
      end.parse(ARGV)
    end

    def self.load_configuration_from_working_directory
      ['marathonr.config', '.marathonr'].each do |file|
        if File.exist?(file) and File.readable?(file)
          load_configuration_file(file, true)
          break # only process the first available
        end
      end
    end

    def self.load_configuration_file file, be_gentle=false
      data = File.read(file)
      yml = YAML.load(data)
      unless yml.is_a?(Hash)
        raise TypeError, "Did not receive hash from YAML in #{filename}"
      end
      yml.each do |k,v|
        if !be_gentle or @configuration.default?(k.to_sym)
          @configuration[k.to_sym] = v
        end
      end
    end

    def self.set_table_name
      if @configuration[:table_name]
        WorkRequest.set_table_name(@configuration[:table_name])
      end
    end

    ##
    # A wrapper around Hash that tracks if a value has been changed or remains
    # the default.
    #
    class Configuration
      def initialize values={}
        @changed_fields = {}
        @_h = values
        values.each{|k,v| @_h[k] = v}
      end

      def [] key
        @_h[key]
      end

      def []= key, value
        @_h[key] = value
        @changed_fields[key] = true
      end

      def changed? key
        @changed_fields[key]
      end

      def default? key
        !changed?(key)
      end

      def symbolize_keys
        @_h.symbolize_keys
      end
    end
  end
end
