require 'pragmatic_context/default_contextualizer'

describe PragmaticContext::DefaultContextualizer do
  describe 'adding terms' do
    it 'should add terms and be able to retrive them' do
      subject.add_term('bacon', :as => 'http://bacon.com', :type => 'number')
      subject.add_term('ham', :as => 'http://ham.com')
      subject.definitions_for_terms(%w(bacon ham)).should eq({
        "bacon" => { "@id" => "http://bacon.com", "@type" => "number" },
        "ham" => "http://ham.com"
      })
    end

    it 'should return all terms when asked' do
      subject.add_term('bacon', :as => 'http://bacon.com', :type => 'number')
      subject.add_term('ham', :as => 'http://ham.com')
      subject.definitions_for_terms.should eq({
        "bacon" => { "@id" => "http://bacon.com", "@type" => "number" },
        "ham" => "http://ham.com"
      })
    end
  end
end
