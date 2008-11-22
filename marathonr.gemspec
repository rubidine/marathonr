Gem::Specification.new do |s|

  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=

  s.date = '2008-05-23'
  s.name = 'marathonr'
  s.version = '0.0.1'
  s.authors = ['Todd Willey']
  s.email = 'todd@rubidine.com'
  s.homepage = 'http://github.com/rubidine/'
  s.summary = 'ActiveRecord-based job runner'
  s.description = 'MarathonR is a queue processing service that starts background runners.  It uses ActiveRecord to store pending and completed requests.'

  s.default_executable = 'marathonr'
  s.executables = ['marathonr', 'marathonr_migrate']
  s.require_paths = ['lib']

  s.has_rdoc = true
  s.extra_rdoc_files = ['README']
  s.rdoc_options = ["--line-numbers", "--inline-source", "--main", "README", "--title", "MarathonR -- ActiveRecord-based job runners"]

  s.rubyforge_project = 'rubidine'

  s.files = Dir['lib/**/*'] + Dir['migrations/*'] + Dir['bin/*'] + ['MIT-LICENSE', 'README']
end
