MRuby::Gem::Specification.new('mruby-virtualing') do |spec|
  spec.license = 'MIT'
  spec.authors = 'MATSUMOTO Ryosuke'
  spec.version = '0.0.1'
  spec.add_dependency('mruby-cgroup')
  spec.add_dependency('mruby-process')
end
