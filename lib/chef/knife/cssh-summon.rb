require 'chef/knife'

module KnifeCssh

  def self.which(*cmds)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']

    cmds.each do |cmd|
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end
    end

    return nil
  end

  class CsshSummon < Chef::Knife

    banner "knife cssh summon QUERY"

    option :login,
      :short => '-l USER',
      :long => '--login USER',
      :description => 'Username to use for login',
      :default => 'root'

    option :cssh_command,
      :short => '-c COMMAND',
      :long => '--cssh-command COMMAND',
      :description => 'Command to use instead of cssh/csshX',
      :default => KnifeCssh::which('csshX', 'cssh'),
      :proc => Proc.new { |cmd| KnifeCssh::which cmd }

    deps do
      require 'chef/node'
      require 'chef/environment'
      require 'chef/api_client'
      require 'chef/knife/search'
      require 'shellwords'
    end

    def run
      # this chef is mainly from chef own knife search command
      if name_args.length < 1
        puts 'Missing argument QUERY!'
        show_usage
        exit 1
      end

      query = name_args[0]
      q = Chef::Search::Query.new
      escaped_query = URI.escape(query, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      result_items = []

      begin
        q.search('node', escaped_query, 'X_CHEF_id_CHEF_X asc', 0, 100) do |item|
          remote_host = extract_host item
          result_items.push remote_host if not remote_host.nil?
        end
      rescue Net::HTTPServerException => e
        msg = Chef::JSONCompat.from_json(e.response.body)["error"].first
        ui.error("search failed: #{msg}")
        exit 1
      end

      %x[#{config[:cssh_command]} -l #{config[:login].shellescape} #{result_items.join(" ")}]
    end

    private

    def extract_host(item)
      return item[:ec2][:public_ipv4] if item.has_key? :ec2
      return item[:ipaddress] if not item[:ipaddress].nil?
      item[:fqdn]
    end
  end
end
