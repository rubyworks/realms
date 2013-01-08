#!/usr/bin/env sh

pwddir=$(pwd)
tmpdir="/tmp/rolls-install"

mkdir $tmpdir
cd $tmpdir

wget https://github.com/rubyworks/autoload/archive/master.zip
unzip master.zip
rm master.zip

wget https://github.com/rubyworks/versus/archive/master.zip
unzip master.zip
rm master.zip

wget https://github.com/rubyworks/library/archive/master.zip
unzip master.zip
rm master.zip

wget https://github.com/rubyworks/rolls/archive/master.zip
unzip master.zip
rm master.zip

cd autoload-master
ruby setup.rb
cd ..

cd versus-master
ruby setup.rb
cd ..

cd library-master
ruby setup.rb
cd ..

cd rolls-master
ruby setup.rb
cd ..

cd $pwddir
rm -r $tmpdir

