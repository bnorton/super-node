module SuperNode
class Nom
  def locations
    items = nil
    time = Benchmark.measure do
      url = "https://justnom.it/locations/here.json?lat=37.7969398498535&lng=-122.399559020996"

      items = 100.times.collect do
        t = {}
        t[:time] = Time.now
        t[:body] = SuperNode::HTTP.new(url).get.body
        t[:total] = ((Time.now - t[:time]) * 1000)
        t
      end
    end
    File.open(File.join(Rails.root, 'tmp', "nom#{Time.now.utc.to_s.gsub(' ', '-')}.txt"), 'w+') {|f| f.write("TIME: #{time} - #{ActiveSupport::JSON.encode(items)}") }
  end

  def perform
    puts "PERFORMED!!!!"
  end
end
end