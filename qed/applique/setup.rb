require 'fileutils'

# setup clean temporary locations
FileUtils.rm_r('tmp') if File.exist?('tmp')

