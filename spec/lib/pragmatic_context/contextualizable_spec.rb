require 'pragmatic_context'

class Stub
  include PragmaticContext::Contextualizable

  attr_accessor :bacon

  def attributes
    { "bacon" => bacon }
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

    describe 'context' do
      it 'should properly marshall together term definitions with the appropriate terms' do
        property = double('property')
        property.stub(:to_definition_hash) { { "@id" => "http://bacon.yum" } }
        @contextualizer.stub(:properties_for_terms) do |properties|
          { 'bacon' => property }.slice(*properties)
        end
        subject.bacon = 'crispy'
        subject.context['bacon']['@id'].should == 'http://bacon.yum'
      end
    end

    describe 'uncontextualized_terms' do
      it 'should include terms which are not contextualized by the configured Contextualizer' do
        @contextualizer.stub(:properties_for_terms) { {} }
        subject.uncontextualized_terms.should == ['bacon']
      end
    end
  end
end

