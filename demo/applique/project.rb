require 'pathname'

project_directory = Pathname.new('projects')

When 'Given a project directory "(((\S+)))"' do |name|
  @project_directory = project_directory + name
  libdir = @project_directory + 'lib'
  FileUtils.mkdir_p(libdir) unless libdir.exist?
end

When 'With a file "(((\S+)))" containing' do |name, text|
  file = @project_directory + name
  FileUtils.mkdir_p(file.parent) unless file.parent.exist?
  File.open(file.to_s, 'w'){ |f| f << text }
end

