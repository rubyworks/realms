require 'pom'
PROJECT = POM::Project.new(Dir.pwd)

desc "Generate RDocs"
task :rdoc => 'doc/rdoc' do
end

directory 'doc/rdoc' do
  system %[rdoc -o doc/rdoc -m README -t "Ruby Rolls" README lib]
end

desc "Install Rolls"
task :install do
  system %[setup.rb]  
end

desc "Build the manual"
task "man" do
  cmd = []
  cmd << "RONN_STYLE='./.config/ronn'"
  cmd << "ronn -br5"
  cmd << "--organization=PROUTILS"
  cmd << "--style='man,toc,center'"
  cmd << "--manual='Roll Manual' man/man1/*.ronn"

  sh cmd.join(' ')

  sh "mkdir -p site/manual/"
  sh "mv man1/*.html site/manual/"

  sh "gzip -f man/man1/*.1"
end

