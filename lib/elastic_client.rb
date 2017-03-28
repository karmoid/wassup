require 'multi_json'
require 'faraday'
require 'elasticsearch/api'

module ElasticClient
  class MySimpleClient
    include Elasticsearch::API

    # CONNECTION = ::Faraday::Connection.new url: 'http://localhost:9200'
    CONNECTION = ::Faraday::Connection.new url: 'http://frmonbcastapp01.emea.brinksgbl.com:9200'

    def json_to_bulk(data)
      data ? (data.map do |item| item.to_json end.join("\n")+"\n") : nil
    end

    def perform_request(method, path, params, body)
      # puts "--> #{method.upcase} #{path} #{params} #{body}"

      CONNECTION.run_request \
        method.downcase.to_sym,
        path,
        ( body ? MultiJson.dump(body): nil ),
        {'Content-Type' => 'application/json'}
    end

    def jsonbody_request(method, path, params, body)
      # puts "--> #{method.upcase} #{path} #{params} #{body}"

      CONNECTION.run_request \
        method.downcase.to_sym,
        path,
        json_to_bulk(body),
        {'Content-Type' => 'application/json'}
    end
  end
end
