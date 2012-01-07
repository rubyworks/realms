#require 'pom'
#PROJECT = POM::Project.new(Dir.pwd)

desc "Install Rolls"
task :install do
  system %[setup.rb]  
end

desc "Build the manual"
task "man" do
  cmd = []
  cmd << "RONN_STYLE='./.config/ronn'"
  cmd << "ronn -br5"
  cmd << "--organization=RUBYWORKS"
  cmd << "--style='man,toc,center'"
  cmd << "--manual='Roll Manual' man/man1/*.ronn"

  sh cmd.join(' ')

  sh "mkdir -p site/manual/"
  sh "mv man1/*.html site/manual/"

  sh "gzip -f man/man1/*.1"
end

