module Accessible
  extend ActiveSupport::Concern

  ACCESSIBILITIES = %w[all members editors admins]

  included do
    validates :access, inclusion: { in: ACCESSIBILITIES }
  end

  def accessible_to?(user)
    self.class.accessibilities_for(user).include?(access)
  end

  module ClassMethods
    def accessibilities_for(user)
      max = case
        when user.admin?  then 3
        when user.editor? then 2
        when user.member? then 1
        else 0
      end
      ACCESSIBILITIES[0..max]
    end

    def accessibility_matches(user, param, matches)
      options = accessibilities_for(user)
      if param.present?
        if options.include?(param)
          matches.where(access: param)
        else
          matches.none
        end
      else
        matches.where(access: options)
      end
    end
  end
end
