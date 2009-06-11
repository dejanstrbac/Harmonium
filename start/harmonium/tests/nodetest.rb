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
# Unit tests for Harmonium Chord nodes
#
# $Id: nodetest.rb 26 2005-02-05 01:47:16Z dido $

require 'test/unit'
require 'harmonium/harmonium'

class NodeTest < Test::Unit::TestCase
  HOST = "127.0.0.1"
  INITPORT = 4096
  NUMNODES = 8

  def test_node

    nodelist = []
    port = INITPORT
    1.upto(NUMNODES) {
      nodelist << Harmonium::Node.new(HOST, port) # new node
      port += 1                 # next port
    }

    # let each node join its predecessor in the list
    1.upto(NUMNODES-1) {
      |i|
      nodelist[i].join(nodelist[i-1].ipaddr, nodelist[i-1].port)
    }

    # For an n-node ring, at least n^2 stabilizations must take
    # place before the ring enters a stable state
    0.upto(NUMNODES-1) {
      0.upto(NUMNODES-1) {
        |i|
        nodelist[i].stabilize
      }
    }

    # Check whether sucessor and predecessor links are proper
    0.upto(NUMNODES-1) {
      |i|
      nid = nodelist[i].nodeid
      assert(!nid.nil?, "nid for #{i} was nil")
      assert(!nodelist[i].pred.nil?, "node #{i} has no successor")
      sid = nodelist[i].succ.nodeid
      assert(!nodelist[i].pred.nil?, "node #{i} has no predecessor")
      pid = nodelist[i].pred.nodeid
      assert(!nid.nil?, "nid was nil")
      assert(!sid.nil?, "sid was nil")
      assert(!pid.nil?, "pid was nil")
    }

    # Traverse the nodes using the successor links.  We must return to
    # the original node after making NUMNODES traversals
    0.upto(NUMNODES-1) {
      |i|
      node = nodelist[i]
      0.upto(NUMNODES-1) {
        node = node.succ
      }
      assert(node.nodeid == nodelist[i].nodeid, "Ring traversal did not return us to the original node on successor links")
    }

    # Traverse the nodes using the predecessor links.  We must return to
    # the original node after making NUMNODES traversals
    0.upto(NUMNODES-1) {
      |i|
      node = nodelist[i]
      0.upto(NUMNODES-1) {
        node = node.pred
      }
      assert(node.nodeid == nodelist[i].nodeid, "Ring traversal did not return us to the original node on predecessor links")
    }

    # Attempt to find the successor of a key, which is a hexadecimal
    # string, with no valid fingers
    s = nodelist[0].find_succ("deadbeef").nodeid
    0.upto(NUMNODES-1) {
      |i|
      st = nodelist[i].find_succ("deadbeef").nodeid
      assert(st == s, "#{i} search using no fingers yielded different results")
    }

    # Fix fingers
    0.upto(NUMNODES-1) {
      |i|
      nodelist[i].fix_fingers
    }

    # Attempt to find the successor of a key, which is a hexadecimal
    # string, with fingers
    sf = nodelist[0].find_succ("deadbeef").nodeid
    assert(sf == s, "search with fingers yields different results from search with no fingers")
    0.upto(NUMNODES-1) {
      |i|
      st = nodelist[i].find_succ("deadbeef").nodeid
      assert(st == s, "#{i} search using fingertable yielded different results")
    }

  end
end
