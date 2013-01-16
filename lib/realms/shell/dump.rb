# Realms 
# Copyright (c) 2013 Rubyworks
# BSD-2-Clause License
#
# encoding: utf-8

module Realms
  class Library

    module Shell

      #
      # Dump the ledger.
      #
      def dump
        opts = {}

        op.banner = "Usage: realm dump"
        op.separator "Dump manager's ledger in serialized format."

        op.on('-j', '--JSON', "Output in JSON format.") do
          opts[:format] = :json
        end

        op.on('-y', '--yaml', "Output in YAML format.") do
          opts[:format] = :yaml
        end

        op.on('-m', '--marshal', "Output in Ruby's own serialization format.") do
          opts[:format] = :marshal
        end

        parse

        case opts[:format]
        when :json
          out = JSON.fast_generate($LOAD_MANAGER.to_h)
        when :yaml
          out = $LOAD_MANAGER.to_h.to_yaml
        when :marshal
          out = Marshal.dump($LOAD_MANAGER.to_h)
        else
          out = JSON.pretty_generate($LOAD_MANAGER.to_h)
        end

        puts out
      end

    end

  end
end
