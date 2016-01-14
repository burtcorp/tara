require 'bundler'
module Bundler
  class Definition
    def add_optional_group(group)
      @optional_groups ||= []
      @optional_groups << group.to_sym
    end
    def has_optional_groups?
      @optional_groups && @optional_groups.is_a?(Array)
    end
  end
end
