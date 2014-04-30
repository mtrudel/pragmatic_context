require 'pragmatic_context'
require 'active_model'

class Stub
  include ActiveModel::Serializers::JSON
  include PragmaticContext::Contextualizable

  attr_accessor :bacon, :ham

  def attributes
    { "bacon" => bacon, "ham" => ham }
  end
end

describe PragmaticContext::Contextualizable do
  describe 'included class methods (configuration DSL)' do
    subject { Stub }

    before :each do
      subject.contextualizer = nil
    end

    describe 'contextualize_with' do
      it 'should set the contextualizer on the class' do
        contextualizer = double('contextualizer')
        contextualizer_class = double('contextualizer class')
        contextualizer_class.stub(:new) { contextualizer }
        subject.contextualize_with contextualizer_class
        subject.contextualizer.should eq contextualizer
      end
    end

    describe 'contextualize' do
      it 'should raise error if contextualize_with has already been called' do
        subject.contextualize_with Object
        expect { subject.contextualize }.to raise_error
      end

      it 'should create properties for each named field' do
        contextualizer = double('contextualizer')
        contextualizer.should_receive(:add_term).with(:bacon, { :as => 'http://bacon.yum' })
        PragmaticContext::DefaultContextualizer.stub(:new) { contextualizer }

        subject.contextualize :bacon, :as => 'http://bacon.yum'
      end
    end
  end

  describe 'included instance methods' do
    subject { Stub.new }

    before :each do
      @contextualizer = double('contextualizer')
      contextualizer_class = double('contextualizer class')
      contextualizer_class.stub(:new) { @contextualizer }
      subject.class.contextualize_with contextualizer_class
    end

    describe 'as_jsonld' do
      it 'should respond with only contextualized terms plus their context' do
        @contextualizer.stub(:definitions_for_terms) do |terms|
          { 'bacon' => { "@id" => "http://bacon.yum" } }.slice(*terms)
        end
        subject.bacon = 'crispy'
        subject.ham = 'honey'
        subject.as_jsonld.should == { "bacon" => "crispy", "@context" => subject.jsonld_context }
      end

      it 'should recurse into Contextualizable subobjects' do
        @contextualizer.stub(:definitions_for_terms) do |terms|
          { 'bacon' => { "@id" => "http://bacon.yum" },
            'ham' => { "@id" => "http://ham.yum" } }.slice(*terms)
        end
        subject.bacon = 'crispy'
        subject.ham = Stub.new
        subject.ham.bacon = 'nested bacon'
        subject.ham.ham = 'nested ham'
        subject.as_jsonld.should == {
          "@context" => subject.jsonld_context,
          "bacon" => "crispy",
          "ham" => {
            "@context" => subject.ham.jsonld_context,
            "bacon" => "nested bacon",
            "ham" => "nested ham"
          }
        }
      end

      it 'should properly render literals within lists' do
        @contextualizer.stub(:definitions_for_terms) do |terms|
          { 'bacon' => { "@id" => "http://bacon.yum" },
            'ham' => { "@id" => "http://ham.yum" } }.slice(*terms)
        end
        subject.bacon = ['crispy', 'back', 'peameal']
        subject.ham = ['honey', 'black forest', 'spiral']
        subject.as_jsonld.should == {
          "@context" => subject.jsonld_context,
          "bacon" => ['crispy', 'back', 'peameal'],
          "ham" => ['honey', 'black forest', 'spiral']
        }
      end

      it 'should recurse into Contextualizable subobjects within lists' do
        @contextualizer.stub(:definitions_for_terms) do |terms|
          { 'bacon' => { "@id" => "http://bacon.yum" },
            'ham' => { "@id" => "http://ham.yum" } }.slice(*terms)
        end
        subject.bacon = [Stub.new]
        subject.ham = [Stub.new, 'honey', Stub.new]
        subject.bacon[0].bacon = 'nested bacon'
        subject.ham[0].ham = 'nested ham'
        subject.ham[2].ham = 'nested ham 2'
        subject.as_jsonld.should == {
          "@context" => subject.jsonld_context,
          "bacon" => [{ "@context" => subject.bacon[0].jsonld_context,
                        "bacon" => "nested bacon",
                        "ham" => nil
                      }],
          "ham" => [{ "@context" => subject.ham[0].jsonld_context,
                      "bacon" => nil,
                      "ham" => "nested ham"},
                    'honey', 
                    { "@context" => subject.ham[2].jsonld_context,
                      "bacon" => nil,
                      "ham" => "nested ham 2"
                    }]
        }
      end

      it 'should compact sub-hashes into namespaced properties on self' do
        @contextualizer.stub(:definitions_for_terms) do |terms|
          { 'bacon' => { "@id" => "http://bacon.yum" },
            'ham' => { "@id" => "http://ham.yum" } }.slice(*terms)
        end
        subject.bacon = 'crispy'
        subject.ham = { 'bacon' => 'nested bacon' }
        subject.as_jsonld.should == {
          "@context" => subject.jsonld_context,
          "bacon" => "crispy",
          "ham:bacon" => "nested bacon"
        }
      end
    end

    describe 'context' do
      it 'should properly marshall together term definitions with the appropriate terms' do
        @contextualizer.stub(:definitions_for_terms) do |terms|
          { 'bacon' => { "@id" => "http://bacon.yum" } }.slice(*terms)
        end
        subject.bacon = 'crispy'
        subject.ham = 'honey'
        subject.jsonld_context['bacon']['@id'].should == 'http://bacon.yum'
        subject.jsonld_context['ham'].should == nil
      end
    end

    describe 'uncontextualized_terms' do
      it 'should include terms which are not contextualized by the configured Contextualizer' do
        @contextualizer.stub(:definitions_for_terms) { {} }
        subject.uncontextualized_terms.should == ['bacon', 'ham']
      end
    end
  end
end
