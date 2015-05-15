class Virtual
  def initialize c
    @config = c
  end
  def run
    setup_cgroup @config[:resource]
    setup_ipalias @config[:ip]
    setup_chroot @config[:jail]
  end
  def setup_cgroup config
    # TODO: implement blkio and mem
    c = Cgroup::CPU.new "mruby-virtual"
    c.cfs_quota_us = config[:cpu_quota]
    c.create
    c.attach
  end
  def setup_ipalias config
    # TODO: implement to mruby-netlink
    run_cmd = "ip addr add #{config[:vip]}/24 dev #{config[:dev]}"
    return if system("ip addr show #{config[:dev]} | grep #{config[:vip]}/24 -q")
    unless system(run_cmd)
      raise "setup ipaliase failed"
    end
  end
  def setup_chroot config
    # TODO: implement to mruby-jailing
    path = config[:path] ? config[:path] : "jailing"
    bind_cmd = config[:bind].map {|dir| "--bind #{dir}" }.join(" ") if config[:bind]
    run_cmd = "#{path} --root=#{config[:root]} #{bind_cmd} -- #{config[:cmnd]}"
    if system(run_cmd)
      raise "setup chroot failed"
    end
  end
end
