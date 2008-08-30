require 'roll/package'


class Library
  INDEX_FILE = "index.yaml"

  # The ledger
  @ledger = {}
  @register = []

  def self.ledger
    @ledger
  end

  def self.register
    @register
  end

  def self.scan
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

  def require(reference)
    match, load_path, paths = nil, nil, nil
    found = Library.register.each do |match, load_path, paths|
      break true if /^#{Regexp.escape(match)}/ =~ reference
    end

    raise unless found

    return Kernel.require(load_path) unless paths

    local_path = reference.sub(/^#{Regexp.escape(match)}/,'')

    paths = [paths].flatten
    paths.each do |path|
      file = File.join(load_path, path, local_path)
      begin
        Kernel.require(file)
      rescue LoadError => e
        puts e.message
      end
    end
  end

end





if __FILE__ == $0

t = Time.now

  Library.scan

p Time.now - t

  #p Library.register

  require 'cgi'

  p CGI

  require 'try/tryme'

  require 'try/tryme'

end
