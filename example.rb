Virtual.new({

  :resource => {
    # CPU [msec] exc: 30000 -> 30%
    :cpu_quota => 30000,
    # IO [Bytes/sec]
    :blk_dvnd => "202:0",
    :blk_rbps => 10485760,
    :blk_wbps => 10485760,
    # Memory [Bytes]
    :mem => 512 * 1024 * 1024,
  },

  :jail => {
    :root => "/tmp/apache",
    :bind => ["/usr/local"],
    :ro_bind => ["/usr/local/lib"],
    :cmnd => "/usr/local/apache/bin/httpd -X"
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
