require 'spec_helper'

describe MatchNodes do
  it 'has a version number' do
    expect(MatchNodes::VERSION).not_to be nil
  end

  describe "matching text content" do
    it "succeeds when text matches" do
      matcher = MatchNodes::Matcher.new("p" => "the textual content")
      text    = "<html><body><p>the textual <span>content</span></p></body></html>"
      expect(matcher.matches? text).to eq true
    end

    it "fails when text does not match" do
      matcher = MatchNodes::Matcher.new("p" => "the textual content")
      text    = "<html><body><p>different textual <span>content</span></p></body></html>"
      expect(matcher.matches? text).to eq false
      expect(matcher.failure_message).to eq <<MSG
selector ---
- p

didn't match expected nodes
--- the textual content
...


got 1 nodes :
<p>different textual <span>content</span></p>
expected text was: the textual content
  actual text was: different textual content
MSG
    end
  end
end
