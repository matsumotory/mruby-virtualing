# virtualing (mruby-virtualing)

creating jail environment, limitting resource and separating filesystem

using https://github.com/kazuho/jailing

## install jailing

See https://github.com/kazuho/jailing

## build virtualing
```
rake
```

and create `virtualing` binary into current directory.

## example
```ruby
# httpd.rb
Virtual.new({

  :resource => {

    :group => "httpd-jail",

    # CPU Limit 30%
    :cpu_quota => 30000,

    # IO Limit 10 MByte/sec
    :blk_dvnd => "202:0",
    :blk_rbps => 10485760,
    :blk_wbps => 10485760,

    # TODO
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

# umount example
# for dir in `mount | grep /var/httpd-jail | awk '{print $3}'`; do sudo umount $dir; done

# del vip
# ip addr del $VIP/24 dev eth0
```

## run
```
sudo ./virtualing httpd.rb
```
