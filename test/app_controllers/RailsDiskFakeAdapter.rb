
class RailsDiskFakeAdapter

  def method_missing(sym, *args, &block)
    @@adaptee ||= DiskFake.new
    @@adaptee.send(sym, *args, &block)
  end

  def self.reset
    @@adaptee = nil
  end

end
