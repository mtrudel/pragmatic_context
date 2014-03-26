require 'active_support'
require 'active_support/hash_with_indifferent_access'

require 'pragmatic_context/term_definition'

module PragmaticContext
  class DefaultContextualizer
    def add_term(term, params)
      @properties ||= ActiveSupport::HashWithIndifferentAccess.new
      @properties[term] = TermDefinition.new(params)
    end

    def properties_for_terms(terms)
      @properties.slice(*terms)
    end
  end
end
