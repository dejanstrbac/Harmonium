#!/usr/bin/env ruby
#
# Copyright (C) 2005 Rafael Sevilla
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
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307 USA.
#
# All Tests Runner
#
# $Id: ALL-TESTS.rb 51 2006-07-24 06:36:00Z dido $
#
$:.unshift "../lib"

Dir.chdir File.dirname(__FILE__)
Dir["**/*_test.rb"].each { |file| load file }
