require 'chef/knife'

module KnifeCssh
  class CsshSummon < Chef::Knife

    banner "knife cssh summon QUERY"

    option :debug,
      :short => '-d',
      :long  => '--debug',
      :description => "turn debug on",
      :default => false

    deps do
      require 'chef/node'
      require 'chef/environment'
      require 'chef/api_client'
      require 'chef/knife/search'
    end

    def run
      # this chef is mainly from chef own knife search command
      query = name_args[0]
      q = Chef::Search::Query.new
      escaped_query = URI.escape(query, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      result_items = []

      begin
        q.search('node', escaped_query, 'X_CHEF_id_CHEF_X asc', 0, 100) do |item|
          result_items.push(item["fqdn"]) if item.has_key?("fqdn")
        end
      rescue Net::HTTPServerException => e
        msg = Chef::JSONCompat.from_json(e.response.body)["error"].first
        ui.error("search failed: #{msg}")
        exit 1
      end

      %x[cssh #{result_items.join(" ")}]
    end
  end
end
