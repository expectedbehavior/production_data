Gem::Specification.new do |s|
  s.name        = 'production_data'
  s.version     = '0.0.1'
  s.date        = '2012-02-15'
  s.summary     = "Get you some production data!"
  s.description = "A gem to pull down production data, sanitize it, and import it for local development and testing."
  s.authors     = ["Jason Gladish"]
  s.email       = 'support@expectedbehavior.com'
  s.files       = ["lib/production_data.rb"]
  s.executables << 'db_setup'
  s.homepage    =
    'https://github.com/expectedbehavior/production_data'
  
  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<highline>, [">= 1.5.2"])
    else
      s.add_dependency(%q<highline>, [">= 1.5.2"])
    end
  else
    s.add_dependency(%q<highline>, [">= 1.5.2"])
  end
end
