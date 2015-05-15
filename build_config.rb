MRuby::Build.new do |conf|
  toolchain :gcc
  conf.gembox 'full-core'
  conf.gem :github => 'iij/mruby-process'
  conf.gem :github => 'matsumoto-r/mruby-cgroup'
  conf.gem './'
end
