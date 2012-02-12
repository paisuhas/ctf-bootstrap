require 'yaml'
require File.expand_path('proc', File.dirname(__FILE__))

class CTFBootstrap

  def self.run!(config)
    @@config = YAML.load_file(config)
    $DEBUG = 1 if @@config['debug'] == true
    validate_config()
    print_info "setting up #{n} levels"
    setup_users()
  end

#  private

  def self.validate_config()
    reqs = ['debug', 'num_levels', 'code_path', 'passwords']
    reqs.each do |req|
      print_error("missing required config option #{req}") if @@config[req].nil?
    end
  end

  # create users, set up passwords
  def self.setup_users()
    usernames.each { |user| execute "useradd #{user}" }
    stdin = usernames.zip(passwords).map { |s| s.join(":") }.join("\n") + "\n"
    print_info stdin.split("\n").join('\n')
    execute('chpasswd', {:stdin => Subprocess::PIPE}) do |pid, io, x, y|
      io.write("#{stdin}")
    end
  end

  # set up code
  def self.setup_levels()

  end

  # execute a command depending on debug mode
  # using the subprocess module in proc.rb
  def self.execute(cmd, opts = {})
      print_info("running command '#{cmd}'...")
      out = 42
      unless $DEBUG
        begin
          out = Subprocess.run([cmd], opts)
          print_cmd_error(cmd, out[2]) if out[2] != ''
          out
        rescue Exception => e
          print_cmd_error(cmd, e.message)
        end
      end
      out
  end

  # config stuff

  def self.n; @@config['num_levels'] end

  def self.usernames; (1..n).to_a.map { |n| "level%02d" % n } end

  def self.passwords
    passwds = @@config['passwords']
    print_error("Not enough passwords specified in config.") unless passwds.length == n
    passwds
  end


  # debug

  def self.print_info(msg); puts "[info] #{msg}\n" end

  def self.print_cmd_error(cmd, msg)
    print_error("unable to execute command '#{cmd}': #{msg}")
  end

  def self.print_error(msg); puts "[error] #{msg}"; exit(1) end
end