#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

class Workspace::TasksController < WorkspaceController

  include ::Concerns::HTTP
  include ::Concerns::UrlBuilder

  skip_before_action :require_sign_in, only: [:show]

  def retry
    set_task
    url = service_base_url(Settings.services.dispatcher.http) +
      "/tasks/#{@task.id}/retry"
    response = http_do(:post, url)
    case response.status
    when 200..299
      redirect_to workspace_trial_path(JSON.parse(response.body)['id']),
                  flash: { successes: ['A new trial has been created.'] }
    else
      redirect_to workspace_task_path(@task.id),
                  flash: { errors: [" #{response.status} " \
                                    "Retry of task failed! #{response.body}"] }
    end
  end

  def show
    set_task
    require_sign_in unless @task.job.public_view_permission?
  end

  def result
    set_task
  end

  def set_task
    @task = Task.find params[:id]
  end

  def get_current_trial_ids
    @task.reload.trials.reload.select(:id).map(&:id)
  end

end
