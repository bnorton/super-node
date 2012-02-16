Factory.define(:superNode_facebook) do |f|
  f.sequence(:graph_id) {|i| "#EEFF4455{i}"}
  f.sequence(:access_token) {|i| "eeffF4455_id_#{i}"}
  f.relative_url "feed"
end