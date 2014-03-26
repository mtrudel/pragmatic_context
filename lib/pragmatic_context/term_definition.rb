module PragmaticContext
  class TermDefinition
    def initialize(params)
      @params = ActiveSupport::HashWithIndifferentAccess.new(params)
    end

    def to_definition_hash
      result = {}
      result['@id'] = @params['as'] if @params['as']
      result['@type'] = @params['type'] if @params['type']
      result
    end
  end
end
