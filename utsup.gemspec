# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{utsup}
  s.version = "0.0.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nick Merwin"]
  s.cert_chain = ["/Users/mer/.gem/gem-public_cert.pem"]
  s.date = %q{2009-10-01}
  s.default_executable = %q{sup}
  s.description = %q{utsup.com client}
  s.email = ["nick@lemurheavy.com"]
  s.executables = ["sup"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt"]
  s.files = ["bin/sup", "extconf.rb", "History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "lib/config/utsup.sample", "lib/hooks/post-commit", "lib/hooks/post-checkout", "lib/hooks/post-merge", "lib/hooks/post-receive", "lib/sup.rb", "script/console", "script/destroy", "script/generate", "test/test_helper.rb", "test/test_sup.rb"]
  s.homepage = %q{http://github.com/yickster/utsup}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{utsup}
  s.rubygems_version = %q{1.3.4}
  s.signing_key = %q{/Users/mer/.gem/gem-private_key.pem}
  s.summary = %q{utsup.com client}
  s.test_files = ["test/test_helper.rb", "test/test_sup.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<schacon-git>, [">= 0"])
      s.add_development_dependency(%q<hoe>, [">= 2.3.3"])
    else
      s.add_dependency(%q<schacon-git>, [">= 0"])
      s.add_dependency(%q<hoe>, [">= 2.3.3"])
    end
  else
    s.add_dependency(%q<schacon-git>, [">= 0"])
    s.add_dependency(%q<hoe>, [">= 2.3.3"])
  end
end
