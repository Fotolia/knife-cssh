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

  def self.find_command(*cmds)
    cmd = self.which *cmds
    return cmd if not cmd.nil?

    puts "Unable to find any of the commands: #{cmds.join ', '} on PATH!"
    exit 1
  end

  class CsshSummon < Chef::Knife

    banner "knife cssh summon QUERY"

    option :login,
      :short => '-l USER',
      :long => '--login USER',
      :description => 'Username to use for login',
      :default => ENV['USER']

    option :cssh_command,
      :short => '-c COMMAND',
      :long => '--cssh-command COMMAND',
      :description => 'Command to use instead of cssh/csshX',
      :default => KnifeCssh::find_command('csshX', 'cssh'),
      :proc => Proc.new { |cmd| KnifeCssh::find_command(cmd) }

    SPECIFIC_OPTIONS = {
      'tmux-cssh' => {
        :user_switch => '-u'
      },
      :default => {
        :user_switch => '-l'
      }
    }

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

      call_cssh result_items
    end

    private

    def extract_host(item)
      return item[:ec2][:public_ipv4] if item.has_key? :ec2
      return item[:ipaddress] if not item[:ipaddress].nil?
      item[:fqdn]
    end

    def call_cssh(hosts)
      %x[#{config[:cssh_command]} #{get_impl_opt :user_switch} #{config[:login].shellescape} #{hosts.join(" ")}]
    end

    def get_impl_opt(key)
      cmdname = cssh_command_name
      if SPECIFIC_OPTIONS.has_key?(cmdname) and SPECIFIC_OPTIONS[cmdname].has_key?(key)
        return SPECIFIC_OPTIONS[cmdname][key]
      end

      SPECIFIC_OPTIONS[:default][key]
    end

    def cssh_command_name
      File.basename config[:cssh_command]
    end
  end
end
