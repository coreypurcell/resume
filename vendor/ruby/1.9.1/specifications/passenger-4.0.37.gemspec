# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "passenger"
  s.version = "4.0.37"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Phusion - http://www.phusion.nl/"]
  s.date = "2014-01-28"
  s.description = "A modern web server and application server for Ruby, Python and Node.js, optimized for performance, low memory usage and ease of use."
  s.email = "software-signing@phusion.nl"
  s.executables = ["passenger", "passenger-install-apache2-module", "passenger-install-nginx-module", "passenger-config", "passenger-status", "passenger-memory-stats"]
  s.extensions = ["helper-scripts/download_binaries/extconf.rb"]
  s.files = ["bin/passenger", "bin/passenger-install-apache2-module", "bin/passenger-install-nginx-module", "bin/passenger-config", "bin/passenger-status", "bin/passenger-memory-stats", "helper-scripts/download_binaries/extconf.rb"]
  s.homepage = "https://www.phusionpassenger.com/"
  s.require_paths = ["lib"]
  s.rubyforge_project = "passenger"
  s.rubygems_version = "1.8.25"
  s.summary = "A fast and robust web server and application server for Ruby, Python and Node.js"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake>, [">= 0.8.1"])
      s.add_runtime_dependency(%q<daemon_controller>, [">= 1.1.0"])
      s.add_runtime_dependency(%q<rack>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0.8.1"])
      s.add_dependency(%q<daemon_controller>, [">= 1.1.0"])
      s.add_dependency(%q<rack>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0.8.1"])
    s.add_dependency(%q<daemon_controller>, [">= 1.1.0"])
    s.add_dependency(%q<rack>, [">= 0"])
  end
end
