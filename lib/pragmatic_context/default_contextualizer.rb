require 'active_support'
require 'active_support/hash_with_indifferent_access'

module PragmaticContext
  class DefaultContextualizer
    def add_term(term, params)
      @properties ||= ActiveSupport::HashWithIndifferentAccess.new
      @properties[term] = ActiveSupport::HashWithIndifferentAccess.new params
    end

    def definitions_for_terms(terms)
      Hash[@properties.slice(*terms).map { |term, params| [term, definition_from_params(params)] }]
    end

    private

    def definition_from_params(params)
      result = {}
      result['@id'] = params[:as] if params[:as]
      result['@type'] = params[:type] if params[:type]
      result
    end
  end
end
