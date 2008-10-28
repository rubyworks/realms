require 'roll/library'

p Library.list


foolib = Library.open('foo')

p foolib

foolib.require 'tryme'
foolib.require 'trymetoo'

