module AncestralChain
  extend ActiveSupport::Concern

  # TODO Generate a Model that is 1:1 with the includer

  class_methods do
    def ancestry_chain(key, table: nil)
      has_one(:"_#{key}_proxy", class_name: "")

      define_method(:"#{key}") do

      end

      define_method(:"#{key}=") do |value|

      end
    end
  end

end
