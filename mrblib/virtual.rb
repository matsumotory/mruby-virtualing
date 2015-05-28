class Virtualing
  include Cgroup
  def initialize c
    @config = c
    @cgroup_name = c[:resource][:group] ? c[:resource][:group] : "mruby-virtual"
    @cgroup_root = c[:resource][:root] ? c[:resource][:root] : "/cgroup"
    if c[:jailing][:root].nil?
      raise ":jailing => {:root => chroot_paht} is always required."
    end
    @chroot_dir = c[:jailing][:root]
  end
  def copy_into_chroot f
    unless system("cp -f #{f} #{@chroot_dir}#{f}")
      raise "copy failed: #{f}"
    end
  end
  def create_dir_into_chroot dir
    unless File.directory? "#{CHROOT_DIR}/#{dir}"
      run_cmd = "mkdir -p #{CHROOT_DIR}/#{dir}"
      unless system run_cmd
        raise "mkdir failed: #{run_cmd}"
      end
    end
  end
  def bind_mount_into_chroot d
    unless system("test -z '$(ls -A #{CHROOT_DIR}/#{d})'")
      run_cmd = "mount --bind /#{d} #{CHROOT_DIR}/#{d}"
      unless system(run_cmd)
        raise "mount failed: #{run_cmd}"
      end
    end
  end
  def setup_mem_eventfd type, val, e
    # TODO: implement memory method using libcgroup API
    fd = 0
    c = Cgroup::MEMORY.new @cgroup_name
    c.modify
    if type == :oom
      fd = File.open("#{@cgroup_root}/memory/#{@cgroup_name}/memory.oom_control", "r").fileno
      c.cgroup_event_control = "#{e.fd} #{fd}"
    elsif type == :usage && val
      fd = File.open("#{@cgroup_root}/memory/#{@cgroup_name}/memory.usage_in_bytes", "r").fileno
      c.cgroup_event_control = "#{e.fd} #{fd} #{val}"
    else
      raise "invalid mem event type or resource config. :oom or :usage"
    end
    c.modify
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
  def run_with_mem_eventfd_loop type = :oom, val = nil, &b
    e = Eventfd.new 0, 0
    run_on_fork
    fd = setup_mem_eventfd type, val, e
    Signal.trap(:INT) { |signo|
      e.close
      IO.new(fd).close
      exit 1
    }
    Signal.trap(:TERM) { |signo|
      e.close
      IO.new(fd).close
      exit 1
    }
    loop { e.event_read &b }
  end
  def run_on_fork
    pid = Process.fork() do
      run
    end
  end
  def run
    setup_cgroup @config[:resource]
    setup_ipalias @config[:ip] if @config[:ip]
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
    unless config[:oom].nil?
      mem.oom_control = (config[:oom] == true) ? false : true
    end
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
    raise "should set both [:ip][:vip] and [:ip][:dev]" if config[:vip].nil? || config[:dev].nil?
    # TODO: implement to mruby-netlink
    run_cmd = "ip addr add #{config[:vip]}/24 dev #{config[:dev]}"
    return if system("ip addr show #{config[:dev]} | grep #{config[:vip]}/24 -q")
    unless system(run_cmd)
      raise "setup ipaliase failed"
    end
  end
  def setup_chroot config
    # TODO: implement to mruby-jailing
    if ! config[:jailing].nil? && config[:jailing] == false
      run_cmd = "chroot #{config[:root]} #{config[:cmnd]}"
    else
      path = config[:path] ? config[:path] : "jailing"
      bind_cmd = config[:bind].map {|dir| "--bind #{dir}" }.join(" ") if config[:bind]
      robind_cmd = config[:ro_bind].map {|dir| "--robind #{dir}" }.join(" ") if config[:ro_bind]
      run_cmd = "#{path} --root=#{config[:root]} #{bind_cmd} #{robind_cmd} -- #{config[:cmnd]}"
    end
    unless system(run_cmd)
      raise "setup chroot failed"
    end
  end
end
