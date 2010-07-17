require 'erb'

DEMO_DIR = File.dirname(File.dirname(__FILE__))

When '= Use Command' do
  complete_setup
end

When '= Insert Command' do
  FileUtils.rm_r('tmp') if File.exist?('tmp')
  copy_fixture('project_setup')
end

When '= Out Command' do
  complete_setup
end

When '= Show Command' do
  complete_setup
end

When '= Show List' do
  complete_setup
end

When '= List Command' do
  complete_setup
end

When '= Sync Command' do
  complete_setup
end

When '= Copy Command' do
  complete_setup
end

When '= Verify Command' do
  complete_setup
end

When '= Path Command' do
  complete_setup
end

When '= Which Command' do
  complete_setup
end

#
def complete_setup
  FileUtils.rm_r('tmp') if File.exist?('tmp')
  copy_fixture('config_setup')
  copy_fixture('project_setup')
end

#
def copy_fixture(name)
  FileUtils.mkdir_p('tmp')
  srcdir = File.join(DEMO_DIR, 'fixtures', name)
  paths  = Dir.glob(File.join(srcdir, '**', '*'), File::FNM_DOTMATCH)
  paths.each do |path|
    basename = File.basename(path)
    next if basename == '.'
    next if basename == '..'
    dest = File.join('tmp', path.sub(srcdir+'/', ''))
    if File.directory?(path)
      FileUtils.mkdir(dest)
    else
      text = ERB.new(File.read(path)).result
      File.open(dest, 'w'){ |f| f << text }
    end
  end
end

