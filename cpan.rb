require 'puppet/provider/package'
Puppet::Type.type(:package).provide :cpan, :parent => Puppet::Provider::Package do
  desc "CPAN modules support.  You can pass any `source` which `cpanm` support, 
    like URL, git repos and local tar.gz. If source is not present at all,
    the module will be installed from the default CPAN source.
    You must install App::cpanminus, App::pmodinfo, App::pmuninstall before."
  has_feature :versionable
  commands :cpanmcmd => "cpanm"
  commands :pmodinfocmd => "pmodinfo"
  commands :pmuninstallcmd => "pm-uninstall"
  def self.pmodlist(options)
    pmodlist_command = [command(:pmodinfocmd),]
    if options[:local]
      pmodlist_command << "-l"
    else
      pmodlist_command << "-c"
    end
    if name = options[:justme]
      pmodlist_command << name
      list = [execute(pmodlist_command)].map {|set| pmodsplit(set) }.reject {|x| x.nil? }
    else
      list = execute(pmodlist_command).lines.map {|set| pmodsplit(set) }.reject {|x| x.nil? }
    end
    list
  end
  def self.pmodsplit(desc)
    if desc =~ /^(\S+) version is (.+)\.(\n  Last cpan version: (.+))?/
      name = $1
      versions = [$2]
      if latest_version = $3
        versions.unshift($4)
      end
      {
        :name     => name,
        :ensure   => versions,
        :provider => :cpan
      }
    else
      Puppet.warning "Could not match #{desc}" unless desc.chomp.empty?
      nil
    end
  end
  def self.instances(justme = false)
    pmodlist(:local => true).collect do |hash|
      new(hash)
    end
  end
  def install(useversion = true)
    command = [command(:cpanmcmd)]
    resource[:name] += '@' + resource[:ensure] if (! resource[:ensure].is_a? Symbol) and useversion
    command << resource[:name]
    output = execute(command)
    self.fail "Could not install: #{output.chomp}" if output.include?("failed")
  end
  def latest
    pmodinfo_options = {:justme => resource[:name]}
    hash = self.class.pmodlist(pmodlist_options)
    hash[:ensure][0]
  end
  def query
    self.class.pmodlist(:justme => resource[:name], :local => true)
  end
  def uninstall
    pmuninstallcmd resource[:name]
  end
  def update
    self.install(false)
  end
end
