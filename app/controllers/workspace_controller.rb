#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.
#

class WorkspaceController < ApplicationController
  include Concerns::ParamsParser
  include Concerns::CommitsFilter

  before_action :require_sign_in

  def index
    @my = my_workspace?
    set_commits_for_index
    @jobs = Job.where(tree_id: @commits.map(&:tree_id)).reorder(created_at: :desc)
  end

  def my_workspace?
    begin
      if current_user and (not current_user.workspace_filters)
        current_user.update! workspace_filters: get_filter_params
      end
      user_workspace_filter.deep_symbolize_keys == get_filter_params.deep_symbolize_keys
    rescue Exception
      false
    end
  end

  def set_commits_for_index
    @commits = Commit.all
    .apply(build_commits_by_repository_name_filter(repository_name_param))
    .apply(build_commits_by_branch_name_filter(branch_name_param))
    .apply(build_text_search_filter(commits_text_search_param))
    .apply(build_git_ref_filter(git_ref_param))
    .apply(build_commits_by_depth_filter(integer_param(:depth, 0)))
    .apply(build_commits_by_page(params[:page], commits_per_page_param))
    .distinct.reorder(committer_date: :desc, depth: :desc)
      .select(:author_email, :committer_email, :author_date, :author_name,
              :committer_date, :committer_name,
              :depth, :id, :subject, :tree_id, :updated_at)
  end

  def get_filter_params
    { repository_name: repository_name_param.presence,
      branch_name: branch_name_param.presence,
      git_ref: git_ref_param,
      commits_text_search: commits_text_search_param,
      depth: depth_param,
      per_page: commits_per_page_param
    }
  end

  def filter
    case request.method
    when 'GET'
      redirect_to workspace_path(user_workspace_filter), flash: Hash[flash.to_a]
    when 'POST'
      current_user.update! workspace_filters: get_filter_params
      redirect_to workspace_path(user_workspace_filter)
    end
  end

  def job_tags_filter
    params.try('[]', 'job_tags').presence \
      .split(',').map(&:strip).reject(&:blank?).sort.uniq rescue []
  end

  def tree_id_filter
    params.try('[]', 'tree_id').presence
  end

  def require_sign_in
    render 'public/401', status: :unauthorized unless user?
  end

end
