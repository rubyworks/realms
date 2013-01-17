require 'erb'

$DEMO_DIR = File.dirname(File.dirname(__FILE__))

# Link tmp/qed/projects to fixtures/projects.
FileUtils.ln_s($DEMO_DIR + '/fixtures/projects', 'projects')

#
#def cached_setup
#  Realms::Library::Utils.sync
#end

#
#def live_setup
#  ledger = Dir['cache/ruby/*.ledger'].first
#  FileUtils.rm(ledger) if ledger
#end


=begin
#
def copy_fixture(name)
  srcdir = File.join(DEMO_DIR, 'fixtures', name)
  paths  = Dir.glob(File.join(srcdir, '**', '*'), File::FNM_DOTMATCH)
  paths.each do |path|
    basename = File.basename(path)
    next if basename == '.'
    next if basename == '..'
    dest = path.sub(srcdir+'/', '')
    if File.directory?(path)
      FileUtils.mkdir(dest)
    else
      text = ERB.new(File.read(path)).result
      File.open(dest, 'w'){ |f| f << text }
    end
  end
end
=end
