# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mingle_events}
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Rice"]
  s.date = %q{2011-08-05}
  s.add_dependency('nokogiri')
  s.add_dependency('activesupport')
  s.description = %q{
    Mingle 3.3 introduced a new Events API in the form of an "Atom feed":http://www.thoughtworks-studios.com/mingle/3.3/help/mingle_api_events.html. The Mingle team and ThoughtWorks Studios are big believers in the use of Atom for exposing events. Atom is a widely used standard, and this event API style puts the issue of robust event delivery in the hands of the consumer, where it belongs. In fact, we'd argue this is the only feasible means of robust, scalable event delivery, short of spending hundreds of thousands or millions of dollars on enterprise buses and such. Atom-delivered events are cheap, scalable, standards-based, and robust.

    However, we do accept that asking integrators wishing to consume events to implement polling is not ideal. Writing polling consumers can be tedious. And this tedium gets in the way of writing sweet Mingle integrations. We are addressing this by publishing libraries such as this, which if effective, fully hide the mechanics of event polling from the consumer. The consumer only need worry about the processing of events. Said processing is modeled in the style of 'pipes and filters.'    
  }
  s.email = %q{david.rice at gmail dot com}
  s.extra_rdoc_files = ["LICENSE.txt", "README.textile"]
  s.files = Dir[
    "Gemfile", 
    "lib/**/*.rb",
    "LICENSE.txt",
    "README.textile",
    "test/**/*.rb"
  ]
  s.homepage = %q{https://github.com/ThoughtWorksStudios/mingle_events}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "mingle_events", "--main", "README.textile"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{mingle_events}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A gem that lets you process Mingle events in a pipes and filters style.}
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
