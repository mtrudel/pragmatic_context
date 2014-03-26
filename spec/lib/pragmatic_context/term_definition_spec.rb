require 'pragmatic_context/term_definition'

describe PragmaticContext::TermDefinition do
  describe 'to_definition_hash' do
    it 'should build it correctly' do
      subject = PragmaticContext::TermDefinition.new(:as => 'http://foo.com', :type => 'range')
      subject.to_definition_hash.should eq({ "@id" => 'http://foo.com', "@type" => 'range' })
    end

    it 'should not specify a type if it is a native JSON type' do
      pending 'type support'
      subject = PragmaticContext::TermDefinition.new(:as => 'http://foo.com', :type => 'string')
      subject.to_definition_hash.should eq({ "@id" => 'http://foo.com' })
    end
  end
end
