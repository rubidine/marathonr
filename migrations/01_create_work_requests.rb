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

##
# The migration
#
class CreateWorkRequests < ActiveRecord::Migration
  def self.up
    return if Marathonr::WorkRequest.table_exists?

    create_table :work_requests do |t|
      t.string :worker_name, :null => false
      t.string :job_key, :null => false

      t.binary :data
      t.string :status_message

      t.boolean :pending, :default => true
      t.boolean :complete, :default => false
      t.boolean :success, :default => true
      t.boolean :error, :default => false

      t.string :filetype
      t.string :filename

      t.integer :current_stage_step, :default => 0
      t.integer :current_stage_max_step, :default => 0

      t.string :current_stage_name, :default => 'Initializing'
      t.integer :current_stage_number, :default => 0
      t.integer :max_stage_number, :default => 0

      t.timestamps
    end
  end

  def self.down
    drop_table :work_requests if Marathonr::WorkRequest.table_exists?
  end
end

CreateWorkRequests.up
#CreateWorkRequests.down
