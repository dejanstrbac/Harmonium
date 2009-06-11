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
# $Id: node_test.rb 64 2006-10-23 18:31:19Z zond $

require File.join(File.dirname(__FILE__), 'test_helper')
require 'harmonium'

class NodeTest < Test::Unit::TestCase
  HOST = "127.0.0.1"
  INITPORT = 4096
  NUMNODES = 16

  def setup
    Harmonium::Node.validate_nodeid = false
    Harmonium::Node.calculate_coordinates = false
    Harmonium::Node.remote_node_class = Harmonium::RemoteNode
  end

  class FakeNode < Harmonium::Node
    def nodeid=(i)
      @nodeid = i
      @succ = Harmonium::RemoteNode.new(self)
    end
  end

  def test_fake_node
    begin
      nodelist = build_nodelist(NUMNODES, INITPORT)
      
      Harmonium::Node.validate_nodeid = true
      fake_node = FakeNode.new("druby://#{HOST}:#{INITPORT + nodelist.size}")
      fake_node.nodeid = Digest::SHA1.new("i am a little mouse").to_s[0..Harmonium::MAX_LEN]
      fake_node.join(nodelist.first.uri)
      
      complete_list = nodelist.clone
      complete_list << fake_node
      
      assert_raise(Harmonium::NodeError) do
        stabilize_ring(complete_list)
      end
    ensure
      stop_nodelist(nodelist)
    end
  end

  #
  # To test the synthetic coordinates
  # we need a new class of RemoteNode that
  # fakes the distance it perceives.
  #
  # To do this we create this DistancedRemoteNode
  # that adds an artificial distance based
  # on a given hash of coordinates by nodeid.
  #
  class DistancedRemoteNode < Harmonium::RemoteNode
    @@coords_by_nodeid = {}
    def self.coords_by_nodeid=(c)
      @@coords_by_nodeid = c
    end
    def calculate_distance(options)
      if @@coords_by_nodeid.empty?
        options[:time_delta]
      else
        r = (@@coords_by_nodeid[options[:self_nodeid]] -
             @@coords_by_nodeid[options[:holder_nodeid]]).r
        r
      end
    end
  end

  def test_synthetic_coordinates
    begin
      Harmonium::Node.remote_node_class = DistancedRemoteNode
      
      nodelist = build_nodelist(NUMNODES / 4, INITPORT)
      
      Harmonium::Node.calculate_coordinates = true
      
      coords_by_nodeid = {}
      nodelist.each do |node|
        coords_by_nodeid[node.nodeid] = Vector[*Array.new(3).collect do |e|
                                                 (rand - 0.5) * 1000.0
                                               end]
      end
      DistancedRemoteNode.coords_by_nodeid = coords_by_nodeid
      
      0.upto(nodelist.size) do |n|
        nodelist.each do |node|
          node.stabilize
        end
      end
      
      errors = error_stats(nodelist)
      
      20.times do
        check_ring(nodelist)
      end      
      
      new_errors = error_stats(nodelist)
      
      excellence = 2
      errors.each do |key, val|
        assert(errors[key] > excellence * new_errors[key], "#{key} for old errors (#{val}) is not #{excellence} times #{key} for new errors (#{new_errors[key]}), either something is broken or we need to do more processing to achieve that level of excellence...")
      end
    ensure
      stop_nodelist(nodelist)
    end
  end

  def test_node
    begin
      nodelist = build_nodelist(NUMNODES, INITPORT)
      
      check_ring(nodelist)
      
      #
      # Fail 10% of the nodes and see if they can repair the ring.
      #
      0.upto(NUMNODES / 10) do |i|
        n = rand(nodelist.size)
        nodelist[n].drb.stop_service()
        nodelist.delete(n)
      end
      
      check_ring(nodelist)
    ensure
      stop_nodelist(nodelist)
    end
  end

  private

  def error_stats(nodelist)
    errors = []
    avg_error = 0
    min_error = 1 << 10
    max_error = -1
    nodelist.each do |node|
      this_error = node.mean_error
      errors << this_error
      avg_error += this_error
      min_error = this_error if min_error > this_error
      max_error = this_error if max_error < this_error
    end
    {
      :min => min_error, 
      :max => max_error, 
      :avg => avg_error / nodelist.size.to_f,
      :med => errors.sort[errors.size / 2]
    }
  end

  def build_nodelist(size, initport)
    nodelist = []
    port = initport
    1.upto(size) do
      nodelist << Harmonium::Node.new("druby://#{HOST}:#{port}") # new node
      port += 1                 # next port
    end

    # Let each node join its predecessor in the list
    1.upto(size-1) do |i|
      nodelist[i].join(nodelist[i-1].uri)
    end
    nodelist
  end

  def stop_nodelist(list)
    list.each do |n|
      n.drb.stop_service()
    end
    DRb.stop_service
  end

  def stabilize_ring(nodelist)
    # For an n-node ring, at least n^2 stabilizations must take
    # place before the ring enters a stable state
    0.upto(nodelist.size) do |n|
      nodelist.each do |node|
        node.stabilize
      end
    end
  end

  def ring_finger(nodelist)
    # Fix fingers lots of times
    0.upto(160) do
      nodelist.each do |node|
        node.fix_fingers
      end
    end
  end

  #
  # Checks that a +nodelist+ of connected but not properly stabilized and fingered
  # nodes can do proper service.
  #
  def check_ring(nodelist)

    stabilize_ring(nodelist)

    # Check whether sucessor and predecessor links are proper
    nodelist.each do |node|
      nid = node.nodeid
      assert(!nid.nil?, "nid for #{node} was nil")
      assert(!node.pred.nil?, "node #{node} has no successor")
      sid = node.succ.nodeid
      assert(!node.pred.nil?, "node #{node} has no predecessor")
      pid = node.pred.nodeid
      assert(!nid.nil?, "nid was nil")
      assert(!sid.nil?, "sid was nil")
      assert(!pid.nil?, "pid was nil")
    end

    # Traverse the nodes using the successor links.  We must return to
    # the original node after making NUMNODES traversals
    nodelist.each do |node|
      successor = node
      0.upto(NUMNODES-1) do
        successor = successor.succ
      end
      assert(successor.nodeid == node.nodeid, "Ring traversal did not return us to the original node on successor links")
    end

    # Traverse the nodes using the predecessor links.  We must return to
    # the original node after making NUMNODES traversals
    nodelist.each do |node|
      predecessor = node
      0.upto(NUMNODES-1) do
        predecessor = predecessor.pred
      end
      assert(predecessor.nodeid == node.nodeid, "Ring traversal did not return us to the original node on predecessor links")
    end

    # Assert that all nodes return the same succ on the same key without valid fingers
    nids = []
    keys = []
    data = []
    0.upto(NUMNODES) do |test_n|
      data[test_n] = (0..10).collect do |n| 
        (rand(26) + 65).chr 
      end.join
      keys[test_n] = Digest::SHA1.new(data[test_n]).to_s[0..Harmonium::MAX_LEN]
      
      # Attempt to find the successor of a key, which is a hexadecimal
      # string, with no valid fingers
      nids[test_n] = nodelist.first.find_succ(keys[test_n]).nodeid
      nodelist.each do |node|
        st = node.find_succ(keys[test_n]).nodeid
        assert(st == nids[test_n], "#{node} search using no fingers yielded different results")
      end
    end

    # Make sure that every node returns the right node on a random lookup
    nodelist.each do |node|
      random_node = nodelist[rand(nodelist.size)]
      result = node.find_succ(random_node.nodeid)
      assert_equal(random_node.nodeid, result.nodeid)
      assert(Harmonium::RemoteNode === result)
    end

    # fix the fingers of the nodelist
    ring_finger(nodelist)

    # assert that all the fingers in all the nodes have the right holder
    nodelist.each do |node|
      node.finger.each do |remote_node|
        assert(!remote_node.nil?)
        assert_equal(node.nodeid, remote_node.holder.nodeid)
      end
    end

    # assert that all nodes return the same successor on the same key _with_ valid fingers
    0.upto(NUMNODES) do |test_n|

      # Attempt to find the successor of a key, which is a hexadecimal
      # string, with fingers
      sf = nodelist.first.find_succ(keys[test_n]).nodeid
      assert(sf == nids[test_n], "search with fingers yields different results from search with no fingers")
      nodelist.each do |node|
        st = node.find_succ(keys[test_n]).nodeid
        assert(st == nids[test_n], "#{node} search using fingertable yielded different results")
      end
      
      # Attempt to use a Chord instance to find the successor of a key
      sc = Harmonium::Chord.new(nodelist.first).query(data[test_n]).nodeid
      assert_equal(nids[test_n], sc, "search using Chord instance yields different results from search with fingers")
      nodelist.each do |node|
        sc = Harmonium::Chord.new(node).query(data[test_n]).nodeid
        assert_equal(nids[test_n], sc, "#{node} searchusing Chord instance yielded different results")
      end
    end
  end

end
