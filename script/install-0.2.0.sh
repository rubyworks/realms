#!/usr/bin/env sh

pwddir=$(pwd)
tmpdir="/tmp/rolls-install"

mkdir $tmpdir
cd $tmpdir

wget https://github.com/rubyworks/autoload/archive/0.3.0.zip
unzip 0.3.0.zip
rm 0.3.0.zip

wget https://github.com/rubyworks/versus/archive/0.2.0.zip
unzip 0.2.0.zip
rm 0.2.0.zip

wget https://github.com/rubyworks/library/archive/0.2.0.zip
unzip 0.2.0.zip
rm 0.2.0.zip

wget https://github.com/rubyworks/rolls/archive/2.0.0.zip
unzip 2.0.0.zip
rm 2.0.0.zip

cd autoload-0.3.0
ruby setup.rb
cd ..

cd versus-0.2.0
ruby setup.rb
cd ..

cd library-0.2.0
ruby setup.rb
cd ..

cd rolls-2.0.0
ruby setup.rb
cd ..

cd $pwddir
rm -r $tmpdir

