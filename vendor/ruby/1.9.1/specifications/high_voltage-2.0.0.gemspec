# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "high_voltage"
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Jankowski", "Dan Croak", "Nick Quaranto", "Chad Pytel", "Joe Ferris", "J. Edward Dewyea", "Tammer Saleh", "Mike Burns", "Tristan Dunn"]
  s.date = "2013-10-05"
  s.description = "Fire in the disco. Fire in the ... taco bell."
  s.email = ["support@thoughtbot.com"]
  s.homepage = "http://github.com/thoughtbot/high_voltage"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.25"
  s.summary = "Simple static page rendering controller"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<activesupport>, [">= 3.1.0"])
      s.add_development_dependency(%q<appraisal>, [">= 0"])
      s.add_development_dependency(%q<capybara>, ["= 2.0.3"])
      s.add_development_dependency(%q<pry-debugger>, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, [">= 3.1.0"])
      s.add_dependency(%q<appraisal>, [">= 0"])
      s.add_dependency(%q<capybara>, ["= 2.0.3"])
      s.add_dependency(%q<pry-debugger>, [">= 0"])
      s.add_dependency(%q<rspec-rails>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 3.1.0"])
    s.add_dependency(%q<appraisal>, [">= 0"])
    s.add_dependency(%q<capybara>, ["= 2.0.3"])
    s.add_dependency(%q<pry-debugger>, [">= 0"])
    s.add_dependency(%q<rspec-rails>, [">= 0"])
  end
end
