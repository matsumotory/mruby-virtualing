# virtualing (mruby-virtualing)

virtualing is a lightweight virtualization tool for linux processes.

creating jail environment, limiting resouces, assigning IP address and separating filesystem

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

    # cgroup name
    :group => "httpd-jail",

    # cgroup root path
    # centos "/cgroup" by default
    # ubuntu "/sys/fs/cgroup"
    :root => "/cgroup"

    # CPU [msec] exc: 30000 -> 30%
    :cpu_quota => 30000,

    # IO [Bytes/sec]
    :blk_dvnd => "202:0",
    :blk_rbps => 10485760,
    :blk_wbps => 10485760,

    # Memory [Bytes]
    :mem => 512 * 1024 * 1024,
    :oom => true,

  },

  :jail => {
    # use chroot instaed of jailing
    # :jailing => false,
    :path => "/usr/local/bin/jailing",
    :root => "/tmp/apache",
    :bind => ["/usr/local/apache"],
    :ro_bind => ["/usr/local/lib"],
    :cmnd => "/usr/local/apache/bin/httpd -X -f /usr/local/apache/conf/httpd.conf"
  },

  :ip => {
    :vip   => "192.168.0.30",
    :dev  => "eth0",
  },

}).run
# callback memory limit event (default :oom)
# }).run_with_mem_eventfd do |ret|
#   puts "OOM KILLER!!! > #{ret}"
# end

# callback memory limit event for oom
# }).run_with_mem_eventfd(:oom) do |ret|
#   puts "OOM KILLER!!! > #{ret}"
# end

# callback memory limit event for usage(4MByte)
# }).run_with_mem_eventfd(:usage, 4 * 1024 * 1024) do |ret|
#   puts "Usage Up or Down to threadshould !!! > #{ret}"
# end

# umount example
# for dir in `mount | grep /var/httpd-jail | awk '{print $3}'`; do sudo umount $dir; done

# del vip
# ip addr del $VIP/24 dev eth0
```

## run
```
sudo ./virtualing httpd.rb
```
