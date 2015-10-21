require "match_nodes/version"
require "match_nodes/matcher"

module MatchNodes
  def contain_html_nodes hsh
    MatchNodes::Matcher.new hsh
  end
end
