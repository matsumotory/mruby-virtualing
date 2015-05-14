# mruby-virtualing

creating jail environment, limitting resource and separating filesystem

using https://github.com/kazuho/jailing

## install jailing

See https://github.com/kazuho/jailing

## mruby build with mruby-virtualing
```ruby
MRuby::Build.new do |conf|
  toolchain :gcc
  conf.gembox 'full-core'
  conf.gem :github => 'iij/mruby-process'
  conf.gem :github => 'matsumoto-r/mruby-cgroup'
end
```

## example
```ruby
Virtual.new({

  :resource => {
    # CPU 30%
    :cpu_quota => 30000,

    # TODO
    #:io_rate => 30000,
    #:mem => 512,
  },

  :jail => {
    :path => "/usr/local/bin/jailing",
    :root => "/tmp/apache",
    :bind => ["/usr/local"],
    :cmnd => "/usr/local/apache/bin/httpd -X -f /usr/local/apache/conf/httpd.conf"
  },

  :ip => {
    :vip   => "192.168.0.30",
    :dev  => "eth0",
  },

}).run
```
