require 'bundler'
module Bundler
  class Definition
    def add_optional_group(group)
      @optional_groups << group.to_sym
    end
    def optional_groups
      @optional_groups
    end
  end
end
