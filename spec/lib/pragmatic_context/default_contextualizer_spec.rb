require 'pragmatic_context/default_contextualizer'

describe PragmaticContext::DefaultContextualizer do
  describe 'adding terms' do
    it 'should add terms and be able to retrive them' do
      PragmaticContext::TermDefinition.should_receive(:new).ordered.with('yum').and_return('YUM')
      PragmaticContext::TermDefinition.should_receive(:new).ordered.with('blackforest').and_return('BLACKFOREST')
      subject.add_term('bacon', 'yum')
      subject.add_term('ham', 'blackforest')
      subject.properties_for_terms(%w(bacon ham)).should eq({ "bacon" => "YUM", "ham" => "BLACKFOREST" })
    end
  end
end
