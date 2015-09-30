require 'date'
require File.join(File.dirname(__FILE__), "lib", "knife-cssh.rb")

Gem::Specification.new do |s|
  s.name        = 'knife-cssh'
  s.version     = KnifeCssh::VERSION
  s.date        = Date.today.to_s
  s.license    =  "3 clauses BSD"
  s.summary     = "Knife cssh plugin"
  s.description = "Summon cssh from a chef search"
  s.authors     = ["Nicolas Szalay"]
  s.email       = 'nico@rottenbytes.info'
  s.files       = %w[
                    README.md
                    lib/knife-cssh.rb
                    lib/chef/knife/cssh-summon.rb
                  ]
  s.homepage    = 'https://github.com/Fotolia/knife-cssh'
end
