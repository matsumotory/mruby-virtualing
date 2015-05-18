class Virtual
  def initialize c
    @config = c
  end
  def run
    setup_cgroup @config[:resource]
    setup_ipalias @config[:ip]
    setup_chroot @config[:jail]
  end
  def setup_cgroup_cpu config
    group = config[:group] ? config[:group] : "mruby-virtual"
    c = Cgroup::CPU.new group
    c.cfs_quota_us = config[:cpu_quota]
    c.create
    c.attach
  end
  def setup_cgroup_blkio config
    group = config[:group] ? config[:group] : "mruby-virtual"
    io = Cgroup::BLKIO.new group
    io.throttle_read_bps_device = "#{config[:blk_dvnd]} #{config[:blk_rbps]}" if config[:blk_rbps]
    io.throttle_write_bps_device = "#{config[:blk_dvnd]} #{config[:blk_wbps]}" if config[:blk_wbps]
    io.create
    io.attach
  end
  def setup_cgroup_mem config
    group = config[:group] ? config[:group] : "mruby-virtual"
    mem = Cgroup::MEMORY.new group
    mem.limit_in_bytes = config[:mem]
    mem.create
    mem.attach
  end
  def setup_cgroup config
    # TODO: implement blkio and mem
    setup_cgroup_cpu config if config[:cpu_quota]
    setup_cgroup_blkio config if config[:blk_dvnd] && config[:blk_rbps] || config[:blk_wbps]
    setup_cgroup_mem config if config[:mem]
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
    robind_cmd = config[:ro_bind].map {|dir| "--robind #{dir}" }.join(" ") if config[:ro_bind]
    run_cmd = "#{path} --root=#{config[:root]} #{bind_cmd} #{robind_cmd} -- #{config[:cmnd]}"
    unless system(run_cmd)
      raise "setup chroot failed"
    end
  end
end
