# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{utsup}
  s.version = "0.1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nick Merwin"]
  s.date = %q{2010-09-20}
  s.default_executable = %q{sup}
  s.description = %q{utsup.com client}
  s.email = ["nick@lemurheavy.com"]
  s.executables = ["sup"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt"]
  s.files = ["bin/sup", "History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "lib/config/utsup.sample", "lib/sup.rb", "lib/sup/differ/differ_control.rb", "lib/sup/differ/differ_run.rb", "lib/sup/differ/differ.rb", "lib/sup/yamlize.rb", "lib/sup/command.rb", "lib/sup/help.rb", "lib/sup/base.rb", "lib/sup/api.rb", "script/console", "script/destroy", "script/generate", "test/test_helper.rb", "test/test_sup.rb", "test/test_yamler.rb"]
  s.homepage = %q{http://github.com/yickster/utsup_gem}
  s.post_install_message = %q{=======================================
UtSup Installed!
=======================================

Be sure to sign up for an account at http://utsup.com

Then, to begin using, first run:

  sup setup

You can view command reference here:

  sup help

Thanks for using UtSup!
  - Lemur Heavy Industries (http://lemurheavy.com)
 }
  s.rdoc_options = [""]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{utsup}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{utsup.com client}
  s.test_files = ["test/test_yamler.rb", "test/test_sup.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<git>, [">= 0"])
      s.add_runtime_dependency(%q<daemons>, [">= 0"])
      s.add_runtime_dependency(%q<terminal_markup>, [">= 0"])
      s.add_development_dependency(%q<rubyforge>, [">= 2.0.4"])
      s.add_development_dependency(%q<hoe>, [">= 2.6.2"])
    else
      s.add_dependency(%q<git>, [">= 0"])
      s.add_dependency(%q<daemons>, [">= 0"])
      s.add_dependency(%q<terminal_markup>, [">= 0"])
      s.add_dependency(%q<rubyforge>, [">= 2.0.4"])
      s.add_dependency(%q<hoe>, [">= 2.6.2"])
    end
  else
    s.add_dependency(%q<git>, [">= 0"])
    s.add_dependency(%q<daemons>, [">= 0"])
    s.add_dependency(%q<terminal_markup>, [">= 0"])
    s.add_dependency(%q<rubyforge>, [">= 2.0.4"])
    s.add_dependency(%q<hoe>, [">= 2.6.2"])
  end
end
