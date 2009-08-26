# TITLE:
#
#   Package Attribiutes DSL
#
#

class Package

  class ValidationError < Exception
  end

  # Attributes DSL
  module Attributes

    def self.included(base)
      base.extend(ClassMethods)
    end

    #
    def valid?
      begin
        validate
        return true
      rescue ValidationError
        return false
      end
    end

    #
    def validate
      self.class.validation.each do |message, block|
        raise(ValidationError, message) unless instance_eval(&block)
      end
    end

    alias_method :assert_valid, :validate

    #

    module ClassMethods

      def instance_attributes
        @@attributes ||= []
      end

      # Define an attribute.

      def attr_accessor(name, *aliases, &blk)
        instance_attributes << name.to_s
        instance_attributes.uniq!
        if blk
          define_method(name, &blk)
          attr_writer(name)
        else
          super(name)
        end
        aliases.each{ |aliaz| alias_accessor(aliaz, name) }
      end

      # Define an attribute alias.

      def alias_accessor(aliaz, name)
        alias_method aliaz, name
        alias_method "#{aliaz}=", "#{name}="
      end

      def validation
        @@validation ||= []
      end

  #     # Does this class provide open access?
  #     def open_access?
  #       false
  #     end

      def validate(message, &block)
        validation << [message, block]
      end

    end
  end

end
