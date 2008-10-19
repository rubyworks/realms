module Roll

  # Remote install cache (hmmm...should this be optional feature?)
  REMOTE_CACHE = File.expand_path( '~/.lib/site_ruby/1.8/' )
  FileUtils.mkdir_p REMOTE_CACHE unless File.directory? REMOTE_CACHE
  $:.unshift REMOTE_CACHE

  #

  def remote_install(fname)
    # Bit of a shortcoming here since it's not very efficient to
    # be searching a remote location for multiple matches.
    # .so suffix must be specified explicity on the remote end.
    fname = fname + '.rb' unless fname =~ /\.rb$/ or fname =~ /\.so$/

    # get signiture
    url = File.join( source, 'meta', 'signitures', fname )
    $stderr << "remote signiture -- " + url if $DEBUG
    sig = URI.parse( url ).read

    # get file
    url = File.join( source, fname )
    $stderr << "remote file -- " + url if $DEBUG
    file = URI.parse( url ).read

    # verify file and signiture
    if Signer.verify?( pubkey, sig, file )
      infile = File.join( REMOTE_CACHE, fname )
      indir = File.dirname( infile )
      FileUtils.mkdir_p indir
      File.open( infile, 'w' ) { |f| f << file }
    else
      raise
    end
  end

end