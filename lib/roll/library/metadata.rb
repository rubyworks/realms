class Library

  ####################
  # LIBRARY METADATA #
  ####################

  PROJECT_FILE = '{meta/,}project{,info}{,.yaml,.yml}'

  # Read metadata, if any exists. Metadata is purely extransous information.
  # Therefore it is kept in a seaprate 'project' file, and only loaded
  # if requested. The metadata will be a Reap::Project object if Reap
  # is installed (providing more intelligent project info), otherwise it
  # will be a simple OpenStruct object.
  #
  # If no metadata is found, return false. If library is ruby's core/standard
  # then, of course, no metadata exits and it also return false.
  #
  # TODO: Should we handle special ruby library differently?

  def metadata
    return @metadata unless @metadata.nil?
    @metadata = (
      if defined?(::Reap)
        ::Reap::Project.load(location) #
      else
        Kernel.require 'ostruct'
        file = Dir.glob(File.join(location,PROJECT_FILE), File::FNM_CASEFOLD).first
        if file
          require 'yaml'
          data = YAML::load(File.open(file))
          OpenStruct.new(data)
        else
          false
        end
      end
    )
  end

  alias_method :info, :metadata

  # If method is missing delegate to metadata, if any.

  def method_missing(s, *a, &b)
    if metadata
      metadata.send(s, *a, &b)
    else
      super
    end
  end

  # Is metadata available?

  def metadata?
    metadata ? true : false
  end


  # TODO Does this library have a remote source?
  #def remote?
  #  metadata? and source and pubkey
  #end
  

  #  def reload_project
  #    #return @projectinfo unless @projectinfo.nil?
  #
  #    #return @projectinfo = {} if name == 'ruby'
  #
  #    #find = File.join(location, '{meta/,}{project}{.yaml,.yml,}')
  #    #file = Dir.glob(find, File::FNM_CASEFOLD).first
  #
  #    return @metadata = {} unless file
  #
  #    @metadata = (
  #      data = YAML::load(File.new(file))
  #      data = data.inject({}){ |h, (k,v)| h[k.to_s.downcase] = v ; h }
  #      data['file']    = file
  #      data['name']    = name
  #      data['version'] = version.to_s
  #      data
  #    )
  #  end

    #def project_file
    #  return @file unless @file.nil?
    #  @file = (
    #    file = Dir.glob(File.join(location,'{,meta/}project{.yaml,.yml,}'), File::FNM_CASEFOLD)[0]
    #    File.file?(file) ? file : false
    #  )
    #end

end

