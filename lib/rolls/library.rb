module Library

  #
  # Activate a library.
  #
  # @return [true,false] Has the library has been activated?
  #
  def activate
    current = $LEDGER[name]

    if Library === current
      raise VersionConflict.new(self, current) if current != self
    else
      ## NOTE: we are only doing this for the sake of autoload
      ## which does not honor a customized require method.
      #if Library.autoload_hack?
      #  absolute_loadpath.each do |path|
      #    $LOAD_PATH.unshift(path)
      #  end
      #end
      $LEDGER[name] = self
    end

    # TODO: activate runtime requirements?
    #verify
  end

  #
  # Take requirements and activate them. This will reveal any
  # version conflicts or missing dependencies.
  #
  # @param [Boolean] development
  #   Include development dependencies?
  #
  def verify(development=false)
    reqs = development ? requirements : runtime_requirements
    reqs.each do |req|
      name, constraint = req['name'], req['version']
      Library.activate(name, constraint)
    end
  end

  #
  # Is this library active in global ledger?
  #
  def active?
    $LEDGER[name] == self
  end

end
