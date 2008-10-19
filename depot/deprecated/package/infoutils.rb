# TITLE:
#
#   InfoUtils
#

class Package

  #

  module InfoUtils

#     def self.included(base)
#       base.extend InfoAttributes
#     end
#
#     # List attributes.
#
#     def attributes
#       self.class.instance_attributes
#     end

    ##########
    # Access #
    ##########

    # Fetch attribute value, but return nil if it doesn't exist.
    #--
    # TODO Use in method missing instead?
    #++

    def [](name)
      begin
        h = send(name)
      rescue NoMethodError
        h = nil
      end
    end

    # Gathers a group of info hash entries into a merged hash.
    # The +names+ are taken in most to least significant order.
    #
    #   gather(:package)
    #
    # TODO Change name of this method to something better?

    def gather( *names )
      result = names.inject({}) do |hash,name|
        attributes.each do |n|
          if n.to_s =~ /^#{name}_(.*?)$/
            hash[$1] = self[n.to_s] if self[n.to_s]
          end
        end
        hash
      end
      result
    end

    # Collects a group of info entries into a hash.
    # Arguments are a list of info entry names and/or
    # a hash or new name to info entry name.
    #
    #   select(:name, :version, :date => :released)
    #
    # This is used to collect info to pass to tools.

    def select( *args )
      maps = (Hash === args.last ? args.pop : {})
      h = {}
      args.each{ |k|    h[k.to_s] = self[k] }
      maps.each{ |k, i| h[k.to_s] = self[i] }
      h
    end

    # Arbitrary information.
    #
    # TODO Perhaps not define this at all if open_access? is false.

#     def method_missing( s, *a, &b )
#       super unless self.class.open_access?
#       s = s.to_s
#       if s[-1,1] == '='
#         (class << self; self; end).class_eval do
#           attr_accessor s.chomp('=')
#         end
#         send(s,*a,&b)
#       else
#         nil #super
#       end
#     end

    ##############
    # CONVERSION #
    ##############

    # Order of attributes for yaml conversion.

    def to_yaml_properties
      attributes.collect{ |a| "@#{a}" }
    end

    # Use YAML format.

    def to_yaml( opts={} )
      require 'yaml'
      super
    end

    # For yaml conversion, no tag.

    def taguri; nil; end

    # Convert to hash.

    def to_hash
      YAML::load(to_yaml)
    end

    # Use generic XML format.

    def to_xml( opts={} )
      raise "not yet implemented"
    end

    # Use XOXO microformat.

    def to_xoxo( opts={} )
      begin
        require 'blow/xoxo'  # EXTERNAL DEPENDENCY!
      rescue LoadError
        puts 'Blow (http://blow.rubyforge.org) is required to use XOXO format'
      end
      XOXO.dump(self.to_hash, opts)
    end

  end

#   # Attributes Storage DSL
#
#   module InfoAttributes
#
#     def instance_attributes
#       @@attributes ||= []
#     end
#
#     # Define an attribute.
#
#     def attr_accessor(name, *aliases)
#       instance_attributes << name.to_s
#       instance_attributes.uniq!
#       super(name)
#       aliases.each{ |aliaz| alias_accessor(aliaz, name) }
#     end
#
#     # Define an attribute alias.
#
#     def alias_accessor(aliaz, name)
#       alias_method aliaz, name
#       alias_method "#{aliaz}=", "#{name}="
#     end
#
#     # Does this class provide open access?
#     def open_access?
#       false
#     end
#   end

end
