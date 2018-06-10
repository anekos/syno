
require 'pathname'


module Path
  def self.var
    Pathname('~/.local/var/lib/syno/').expand_path
  end

  def self.cookie
    self.var + 'cookies'
  end

  def self.last
    self.var + 'last.yaml'
  end
end
