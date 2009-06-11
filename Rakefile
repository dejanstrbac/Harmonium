#
# -*- Ruby -*-
# Copyright (C) 2005,2006 Rafael Sevilla
# This file is part of Harmonium
#
# Harmonium is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1
# of the License, or (at your option) any later version.
#
# RStyx is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with RStyx; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St., Fifth Floor, Boston, MA
# 02110-1301 USA.
#
# $Id: Rakefile 50 2006-07-24 06:32:54Z dido $
# 
require 'rake'
require 'rake/testtask'

SOURCE_FILES = FileList.new do |fl|
  [ "lib", "tests" ].each do |dir|
      fl.include "#{dir}/**/*"
  end
  fl.include "Rakefile"
  fl.exclude(/\bCVS\b/)
end

RCOV_FILES = FileList.new do |fl|
  fl.include SOURCE_FILES
  fl.include "tests/tc_*"
end

task :default => [:units] do
end

desc "Run all tests"
Rake::TestTask.new(:units) do |t|
  	t.pattern = 'tests/*_test.rb'
  	t.verbose = true
  	t.warning = true
end

desc "Generate rcov coverage report of tests"

task :coverage => RCOV_FILES do
  system "rcov -o ../coverage tests/ALL-TESTS.rb"
end

