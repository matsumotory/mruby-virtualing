class Virtual
  def initialize c
    @config = c
    @cgroup_name = c[:resource][:group] ? c[:resource][:group] : "mruby-virtual"
    @cgroup_root = c[:resource][:root] ? c[:resource][:root] : "/cgroup"
  end
  def setup_mem_eventfd type, val, e
    # TODO: implement memory method using libcgroup API
    fd = 0
    if type == :oom
      fd = File.open("#{@cgroup_root}/memory/#{@cgroup_name}/memory.oom_control", "r").fileno
      File.open("#{@cgroup_root}/memory/#{@cgroup_name}/cgroup.event_control", "w") { |evc| evc.write("#{e.fd} #{fd}") }
    elsif type == :usage && val
      fd = File.open("#{@cgroup_root}/memory/#{@cgroup_name}/memory.usage_in_bytes", "r").fileno
      File.open("#{@cgroup_root}/memory/#{@cgroup_name}/cgroup.event_control", "w") { |evc| evc.write("#{e.fd} #{fd} #{val}") }
    else
      raise "invalid mem event type or resource config. :oom or :usage"
    end
    fd
  end
  # type :oom or :usage
  def run_with_mem_eventfd type = :oom, val = nil, &b
    e = Eventfd.new 0, 0
    run_on_fork
    fd = setup_mem_eventfd type, val, e
    e.event_read &b
    e.close
    IO.new(fd).close
  end
  def run_on_fork
    pid = Process.fork() do
      run
    end
  end
  def run
    setup_cgroup @config[:resource]
    setup_ipalias @config[:ip]
    setup_chroot @config[:jail]
  end
  def setup_cgroup_cpu config
    c = Cgroup::CPU.new @cgroup_name
    c.cfs_quota_us = config[:cpu_quota]
    c.create
    c.attach
  end
  def setup_cgroup_blkio config
    io = Cgroup::BLKIO.new @cgroup_name
    io.throttle_read_bps_device = "#{config[:blk_dvnd]} #{config[:blk_rbps]}" if config[:blk_rbps]
    io.throttle_write_bps_device = "#{config[:blk_dvnd]} #{config[:blk_wbps]}" if config[:blk_wbps]
    io.create
    io.attach
  end
  def setup_cgroup_mem config
    mem = Cgroup::MEMORY.new @cgroup_name
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
