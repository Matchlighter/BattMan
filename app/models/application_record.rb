class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  include Lookups

  scope :any_of, ->(*alts) { alts.reduce{|acc, alt| acc.or(alt) } }
end
