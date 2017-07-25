# encoding: utf-8
# BSD 3-Clause License
#
# Copyright (c) 2017, Arista Networks EOS+
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name Arista nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# @author Arista EOS+ Consulting Services <eosplus-dev@arista.com>
module Cvprac
  # CvpRac::Api namespace
  module Api
    # CVP Task api methods
    module Task
      # @!group Task Method Summary

      # Get task data by ID
      #
      # @param [String] task_id The id of the task to execute
      #
      # @return [Hash] request body
      def get_task_by_id(task_id)
        log(Logger::DEBUG) { "#{__method__}: task_id: #{task_id}" }
        begin
          task = @clnt.get('/task/getTaskById.do', data: { taskId: task_id })
        rescue CvpApiError => e
          if e.to_s.include?('Invalid WorkOrderId') ||
             e.to_s.include?('Entity does not exist')
            return nil
          end
        end
        task
      end

      # Get task data by device name (FQDN)
      #
      # @param [String] device Name (FQDN) of a device
      #
      # @return [Hash] request body
      # rubocop:disable Metrics/MethodLength
      def get_pending_tasks_by_device(device)
        log(Logger::DEBUG) { "#{__method__}: device: #{device}" }
        begin
          task = @clnt.get('/task/getTasks.do', data: { queryparam: 'Pending',
                                                        startIndex: 0,
                                                        endIndex: 0 })
        rescue CvpApiError => e
          if e.to_s.include?('Invalid WorkOrderId') ||
             e.to_s.include?('Entity does not exist')
            return nil
          end
        end
        # TODO: filter tasks by device
        task['data']
      end
      # rubocop:enable Metrics/MethodLength

      # Add note to CVP task by taskID
      #
      # @param [String] task_id The id of the task to execute
      # @param [String] note Content of the note
      #
      # @return [Hash] request body
      def add_note_to_task(task_id, note)
        log(Logger::DEBUG) do
          "add_note_to_task: task_id: #{task_id}, note: [#{note}]"
        end
        @clnt.post('/task/addNoteToTask.do',
                   data: { workOrderId: task_id, note: note })
      end

      # Execute CVP task by taskID
      #
      # @param [String] task_id The id of the task to execute
      #
      # @return [Hash] request body
      def execute_task(task_id)
        log(Logger::DEBUG) { "execute_task: task_id: #{task_id}" }
        @clnt.post('/task/executeTask.do', body: { data: [task_id] })
      end
    end
  end
end
