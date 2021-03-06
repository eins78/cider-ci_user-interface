class TrialIssue < ActiveRecord::Base

  TYPE_BS_MAP = { error: :danger, warning: :warning }

  self.inheritance_column = false
  belongs_to :trial

  def bootstrap_type
    TYPE_BS_MAP[type.to_sym]
  end
end
