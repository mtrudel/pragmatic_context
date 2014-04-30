require 'pragmatic_context/default_contextualizer'

module PragmaticContext
  module Contextualizable
    def Contextualizable.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      attr_accessor :contextualizer

      def contextualize_with(klass)
        self.contextualizer = klass.new
      end

      def contextualize(field, params)
        setup_default_contextualizer
        self.contextualizer.add_term(field, params)
      end

      private

      def setup_default_contextualizer
        already_setup = !self.contextualizer.nil? && !self.contextualizer.is_a?(PragmaticContext::DefaultContextualizer)
        raise "Cannot call contextualize if contextualize_with has already been called" if already_setup
        self.contextualizer ||= PragmaticContext::DefaultContextualizer.new
      end
    end

    def as_jsonld(opts = nil)
      # We iterate over terms_with_context because we want to look at our own
      # fields (and not the fields in 'as_json') to case on their class. In the
      # case where we want to serialize directly, we rely on the field value as
      # sourced from as_json
      terms_with_context = self.class.contextualizer.definitions_for_terms(terms).keys
      json_results = as_json(opts).slice(*terms_with_context)
      results = {}
      terms_with_context.each do |term|
        # Don't use idiomatic case here since Mongoid relations return proxies
        # that fail the Contextualizable test
        value = self.send(term)
        if (value.is_a? Contextualizable)
          results[term] = self.send(term).as_jsonld
        elsif (value.is_a? Array)
          results[term] = self.send(term).each_with_index.map do |element, idx|
            if (element.is_a? Contextualizable)
              element.as_jsonld
            else
              json_results[term][idx]
            end
          end
        elsif (value.is_a? Hash)
          self.send(term).each do |key, value|
            results["#{term}:#{key}"] = value
          end
        else
          results[term] = json_results[term]
        end
      end
      results.merge("@context" => context)
    end

    def context
      self.class.contextualizer.definitions_for_terms(terms)
    end

    def uncontextualized_terms
      terms_with_context = self.class.contextualizer.definitions_for_terms(terms).keys
      terms - terms_with_context
    end

    private

    def terms
      as_json.keys
    end
  end
end
