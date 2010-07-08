module Roll

  # Fallback for extended metdata.
  class MetadataRaw

    # Try to determine name from lib/*.rb file.
    #
    # Ideally this will work, but there are many projects that do not
    # follow best practices, so it not always effective.
    #
    # TODO: Search loadpath not just lib/, but search lib first if present.
    # Eiether that or require that lib/ alwasy be in the loadpath. 
    #def load_name_from_loadpath
    #  #libs = loadpath.map{ |lp| Dir.glob(File.join(lp,'*.rb')) }.flatten
    #  libs = Dir.glob(File.join(location, 'lib', '*.rb'))
    #  if !libs.empty?
    #    self.name = File.basename(libs.first).chomp('.rb')
    #    true
    #  else
    #    false
    #  end
    #end

    #
    #def load_name_from_location
    #  fname = File.basename(location)
    #  if /\-\d/ =~ fname
    #    i = fname.rindex('-')
    #    name, vers = fname[0...i], fname[i+1..-1]
    #    self.name    = name
    #    self.version = vers
    #  else
    #    self.name = fname
    #  end
    #end

    #def load_fallback
    #  load_name_from_loadpath
    #  load_version unless @version
    #  if not @version
    #    self.version = '0.0.0'
    #  end
    #  @name
    #end

  end

end

