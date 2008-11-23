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

module Marathonr

  ##
  # Performs the actual polling work.  Fired off by Server.
  #
  class WorkDispatcher
    def initialize config
      @config = config
      @outstanding_tasks = {}
    end

    def dispatch_every sleep_time
      while true
        sweep_completed_processes
        kill_long_processes
        find_and_dispatch_new_processes

        sleep sleep_time
      end
    end

    ##
    # Check the database connection, get all the pending jobs, dispatch them.
    #
    def find_and_dispatch_new_processes
      ensure_connected
      jobs = Marathonr::WorkRequest.pending.find(:all, :limit => max_new_jobs)
      puts "GOT #{jobs.length} REQUESTS" if $DEBUG
      jobs.each{|job| fork_and_record(job)}
    end
    alias dispatch find_and_dispatch_new_processes

    private
    def ensure_connected
      unless Marathonr::WorkRequest.connected?
        puts "Establish Connection" if $DEBUG
        Marathonr::WorkRequest.establish_connection @config
      end

      unless Marathonr::WorkRequest.connection.active?
        puts "Reset Connection" if $DEBUG
        Marathonr::WorkRequest.connection.reconnect!
      end

      puts "CONNECTED" if $DEBUG
    end

    def fork_and_record req
      puts "Dispatching #{req.id}" if $DEBUG
      req.update_attribute :pending, false

      unless loadable_worker?(req)
        mark_bad_worker(req)
        return
      end

      pid = perform_fork(req)
      record_worker(pid, req)
    end

    def perform_fork req
      pid = fork do
              ensure_connected
              begin
                load worker_file_name(req)
                req.worker_name.camelize.constantize.new(req, @config)
                puts "COMPLETED #{req.id}" if $DEBUG
              rescue Exception => ex
                mark_exception(req, ex)
              end
            end

      puts "PID IS #{pid}" if $DEBUG
      pid
    end

    def record_worker pid, req
      @outstanding_tasks[pid] = {
        :work_request_id => req.id,
        :start => Time.now
      }
    end

    def mark_bad_worker req
      puts "BAD WORKER #{req.id}" if $DEBUG
      req.complete = true
      req.success = false
      req.error = true
      req.status_message = "Invalid Worker: #{File.join(@config[:worker_dir], req.worker_name + '.rb')}"
      req.data = nil
      req.save
    end

    def mark_exception req, ex
      puts "EXCEPTION #{req.id}" if $DEBUG
      req.complete = true
      req.success = false
      req.error = true
      req.status_message = "Exception: #{ex.message}"
      req.data = ex.backtrace.join("\n")
      req.save
    end

    def sweep_completed_processes
      return if @outstanding_tasks.empty?
      while p = completed_worker_pid
        @outstanding_tasks.delete(p)
      end
    end

    def kill_long_processes
      return if @outstanding_tasks.empty?

      now = Time.now
      max = @config[:worker_timeout]
      @outstanding_tasks.each do |pid, data|
        if now - data[:start] > max
          Process.kill('TERM', pid)
          mark_request_as_killed(data[:work_request_id])
        end
      end
    end

    def loadable_worker? req
      fname = worker_file_name(req)
      File.exist?(fname) and File.readable?(fname)
    end

    def max_new_jobs
      @config[:max_workers] - @outstanding_tasks.length
    end

    def worker_file_name request
      File.join(@config[:worker_dir], "#{request.worker_name}.rb")
    end

    def completed_worker_pid
      rv = nil
      begin
        rv = Process.waitpid(-1, Process::WNOHANG)
      rescue Errno::ECHILD
        rv = nil
      end
    end
  end
end
