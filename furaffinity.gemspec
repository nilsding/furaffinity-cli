# frozen_string_literal: true

require_relative "lib/furaffinity/version"

Gem::Specification.new do |spec|
  spec.name = "furaffinity"
  spec.version = Furaffinity::VERSION
  spec.authors = ["Georg Gadinger"]
  spec.email = ["nilsding@nilsding.org"]

  spec.summary = "FurAffinity CLI tool"
  spec.description = "A command line tool to interface with FurAffinity"
  spec.homepage = "https://github.com/nilsding/furaffinity-cli"
  spec.license = "AGPLv3"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "httpx", "~> 1.1"
  spec.add_dependency "json"
  spec.add_dependency "nokogiri", "~> 1.15"
  spec.add_dependency "semantic_logger", "~> 4.14"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "zeitwerk", "~> 2.6"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
