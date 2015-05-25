MRuby::Build.new do |conf|
  toolchain :gcc
  conf.gembox 'full-core'
  conf.gem :github => 'iij/mruby-process'
  conf.gem :github => 'iij/mruby-dir'
  conf.gem :github => 'iij/mruby-io'
  conf.gem :github => 'matsumoto-r/mruby-cgroup'
  conf.gem :github => 'matsumoto-r/mruby-eventfd'
  conf.gem :github => 'matsumoto-r/mruby-eventfd'
  conf.gem :github => 'matsumoto-r/mruby-sleep'
  conf.gem :github => 'ksss/mruby-signal'
  conf.gem './'
end
