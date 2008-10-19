require 'roll/library'

if defined? ::Library

  ::Library.setup

else

class Library

  STATIC_LOAD_PATH = $LOAD_PATH.dup

  #INDEX_FILE = "index.yaml"

  # The ledger
  @ledger = Hash.new{ |h,k| h[k] = [] }

  def self.ledger
    @ledger
  end

  def self.scan
    $LOAD_PATH.each do |lpath|
      next unless File.directory?(lpath)
      Dir.chdir(lpath) do
        libs = Dir.glob('*')
        libs.each do |lib|
          name = lib.chomp('.rb').chomp('.so')
          ledger[name] << lpath
        end
      end
    end
  end

=begin
    libraries = Dir.glob('{' + $LOAD_PATH.join(',') + '}/*')
    libraries.each do |load_path|
      if File.file?(load_path)
        name = File.basename(load_path)
        @register << [name, load_path, nil]
        @register << [name.chomp('.rb'), load_path, nil]
      else
        index_file = File.join(load_path, INDEX_FILE)
        if File.file?(index_file)
          data = Roll::Package.open(index_file)
          data.register.each do |match, paths|
            @register << [match, load_path, paths]
          end
        else
          @register << [File.basename(load_path)+'/', load_path, '']
        end
      end
    end
    @register.sort!{ |kv1, kv2| kv2[0] <=> kv1[0] }
  end
=end

  # Inspection.

  def inspect
    if version
      "#<Library #{name}/#{version}>"
    else
      "#<Library #{name}>"
    end
  end

end


module Kernel

  alias_method :require0, :require

  def require(reference)
puts reference
    lib = reference.split('/').first
    name = lib.chomp('.rb').chomp('.so')
    if paths = Library.ledger[name]
      hold = $LOAD_PATH
      begin
        $LOAD_PATH.replace(paths)
        Kernel.require(reference)
      rescue LoadError => e
puts reference + " (error)"
        $LOAD_PATH.replace(Library::STATIC_LOAD_PATH)
        require0(reference)
      ensure
        $LOAD_PATH.replace(hold)
      end
    else
      require0(reference)
    end
  end

end

end



if __FILE__ == $0

t = Time.now

  #Library.scan

now = Time.now
puts "#{now - t} secs"

#Library.ledger.each do |lib, paths|
#  puts lib + " " + paths.join(" ")
#end

  require 'cgi'

  require 'net/http'
  require 'net/http'

  require 'redcloth'

now = Time.now
puts "#{now - t} secs"

end

