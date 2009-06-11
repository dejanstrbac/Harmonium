#!/usr/bin/ruby
#
# Copyright (C) 2005 Rafael Sevilla
# This file is part of Harmonium
#
# Harmonium is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# Harmonium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with the Harmonium; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307 USA.
#
# Unit tests for Harmonium distributed hashes
#
# $Id: dhash_test.rb 58 2006-10-13 02:40:35Z zond $

require File.join(File.dirname(__FILE__), 'test_helper')
require 'harmonium'

class DHashTest < Test::Unit::TestCase
  HOST = "127.0.0.1"
  INITPORT = 4096 * 4
  NUMNODES = 16

  def setup
    Harmonium::Node.calculate_coordinates = false
    Harmonium::Node.validate_nodeid = false

    @nodelist = []
    port = INITPORT
    1.upto(NUMNODES) do
      @nodelist << Harmonium::DHashNode.new("druby://#{HOST}:#{port}", {}) # new dhash node
      port += 1                 # next port
    end

    # let each node join its predecessor in the list
    1.upto(NUMNODES-1) do |i|
      @nodelist[i].join(@nodelist[i-1].uri)
    end

    # For an n-node ring, at least n^2 stabilizations must take
    # place before the ring enters a stable state
    0.upto(NUMNODES-1) do |j|
      0.upto(NUMNODES-1) do |i|
        @nodelist[i].stabilize
      end
    end

    # Fix fingers
    0.upto(NUMNODES-1) do |i|
      0.upto(NUMNODES-1) do |j|
        @nodelist[i].fix_fingers
      end
    end

    # insert keys into the dhash from each node
    0.upto(NUMNODES-1) do |i|
      dh = Harmonium::DHash.new(@nodelist[i])
      dh["k_#{i}"] = "v#{i}"
      dh["k2_#{i}"] = "v2#{i}"
    end

  end

  def teardown
    @nodelist.each do |node|
      node.drb.stop_service()
    end
    DRb.stop_service
  end

  def test_dhash
    # Test if all keys can be reached from each node
    @nodelist.each do |node|
      dh = Harmonium::DHash.new(node)
      0.upto(NUMNODES-1) do |i|
        assert_equal("v#{i}", dh["k_#{i}"])
        assert_equal("v2#{i}", dh["k2_#{i}"])
      end
    end
  end
end
