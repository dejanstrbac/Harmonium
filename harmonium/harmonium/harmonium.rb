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
# Harmonium, a Chord implementation in Ruby
#
# See the paper: "Chord: A Scalable Peer-to-peer Lookup Protocol for
# Internet Applications" by Ion Stoica, Robert Morris, David Liben-Nowell,
# David R. Karger, M. Frans Kaashoek, Frank Dabek, and Hari Balakrishnan
# for more details on how all of this is supposed to work.
# http://pdos.lcs.mit.edu/chord/papers/paper-ton.pdf
# 
# $Id$
#

require 'drb'
require "digest/sha1"

module Harmonium
  KEY_BITS = 160                # SHA-1 bits
  MAX_LEN = (KEY_BITS / 4) - 1
  KEY_MASK = (1 << KEY_BITS) - 1

  # This class contains some basic utility functions for determining
  # whether particular keys are contained within a section of a
  # Chord ring.
  class Util
    # determine whether n and s are between id

    # This utility function determines whether the key id is contained
    # in the closed interval of the Chord ring [n, s].  Not actually
    # used, only present for the sake of completeness.
    def Util.between_cc(id, n, s)
      nid = Integer("0x" + n)
      sid = Integer("0x" + s)
      xid = Integer("0x" + id)
      if nid == sid
	# degenerate interval
	return(true)
      elsif nid < sid
	# interval does not wrap
	return(nid <= xid && sid >= xid)
      else
	# interval wraps
	return(nid <= xid || sid >= xid)
      end
    end

    # Determine whether id is contained in the open interval of the
    # Chord ring (n, s).
    def Util.between_oo(id, n, s)
      nid = Integer("0x" + n)
      sid = Integer("0x" + s)
      xid = Integer("0x" + id)
      if nid == sid
	# degenerate interval
	return(nid != xid)
      elsif nid < sid
	# interval does not wrap
	return(nid < xid && sid > xid)
      else
	# interval wraps
	return(nid < xid || sid > xid)
      end
    end

    # Determine whether id is contained in the half-open interval of the
    # Chord ring [n, s)
    def Util.between_co(id, n, s)
      nid = Integer("0x" + n)
      sid = Integer("0x" + s)
      xid = Integer("0x" + id)
      if nid == sid
	# degenerate interval
	return(nid != xid)
      elsif nid < sid
	# interval does not wrap
	return(nid <= xid && sid > xid)
      else
	# interval wraps
	return(nid <= xid || sid > xid)
      end
    end

    # Determine whether id is contained in the half-open interval of the
    # Chord ring (n, s]
    def Util.between_oc(id, n, s)
      nid = Integer("0x" + n)
      sid = Integer("0x" + s)
      xid = Integer("0x" + id)
       if nid == sid
	# degenerate interval
	return(nid != xid)
      elsif nid < sid
	# interval does not wrap
	return(nid < xid && sid >= xid)
      else
	# interval wraps
	return(nid < xid || sid >= xid)
      end
    end

    # obtain the key to update fingers for
    def Util.fingerval(n, i)
      return(sprintf("%#{MAX_LEN}x", (Integer("0x" + n) + i) & KEY_MASK))
    end
  end

  # This is the definition of a local Chord node
  class Node
    attr_reader :ipaddr, :nodeid, :port
    attr_reader :pred, :succ
    attr_reader :finger		# debugging
    attr_writer :pred

    include DRbUndumped

    def initialize(ipaddr, port)
      # Save the IP address and port and calculate the local node ID
      @ipaddr = ipaddr
      @port = port
      @nodeid = Digest::SHA1.new(@ipaddr + ":#{port}").to_s[0..MAX_LEN]

      # Start accepting drb connections
      DRb.start_service("druby://#{@ipaddr}:#{@port}", self)

      # Initially, we have no predecessor
      @pred = nil

      # Our successor is initially just ourself
      @succ = self

      # Our finger table is initially empty
      @finger = []
      @fingeridx = 0
    end

    # Search the local finger table for the highest predecessor of id.
    # This is used for searching.
    def closest_preceding_node(id)
      (KEY_BITS-1).downto(0) {
        |i|
        break if @finger[i].nil?
        if (Util.between_oo(@finger[i].nodeid, @nodeid, id))
          return(@finger[i])
        end
      }
      # Give up, and just return our successor as the closest
      # preceding node we can find
      return(@succ)
    end

    # We are asked to find the successor of the key id.
    def find_succ(id)
      # First determine if it is between ourself and our successor.
      if Util.between_oc(id, @nodeid, @succ.nodeid)
        # If it is, our successor is the successor of id
        return(@succ)
      else
        # If not, find the closest preceding node from the local
        # finger table and recursively ask it the same thing.  Because
        # of the way finger tables are constructed this ought to
        # eventually converge to the actual successor.
        np = closest_preceding_node(id)
        return(np.find_succ(id))
      end
    end

    # Respond with "pong" for pings.
    def ping
      return("pong")
    end

    # Given the address and port of a known Chord node running on IP address
    # m and port p, join the ring it is part of.
    def join(m, p)
      mn = DRbObject.new(nil, "druby://#{m}:#{p}")
      @succ = mn.find_succ(@nodeid)
    end

    # Node n thinks it might be our predecessor.  Check to see whether it
    # might be right and update as needed.
    def notify(n)
      # If we don't know our predecessor, then any notification is probably
      # correct.
      if @pred.nil?
        @pred = n
        return
      end

      # If we do have a known predecessor, see whether the node doing
      # it has a node id between our known predecessor and ourself.
      # If this is so, then
      if Util.between_oo(n.nodeid, @pred.nodeid, @nodeid)
        @pred = n
      end
    end

    # Called periodically, this method verifies the node's immediate
    # successor, and tells the successor about itself.
    def stabilize
      # Get our current predecessor
      x = @succ.pred
      if (!x.nil? && Util.between_oo(x.nodeid, @nodeid, @succ.nodeid))
        @succ = x
      end
      @succ.notify(self)
    end

    # Called periodically, this method will refresh finger table entries
    def fix_fingers
      @fingeridx = (@fingeridx + 1) % KEY_BITS
      @finger[@fingeridx] = find_succ(Util.fingerval(@nodeid,
                                                     @fingeridx + 1))
      return(@fingeridx)
    end

    # Called periodically, checks whether predecessor has failed
    def check_predecessor
      if !(@pred.nil? || @pred.ping != "pong")
        @pred = nil
      end
    end
  end

  class Chord
    attr_reader :node
    SSLEEPTIME = 10
    FFSLEEPTIME = 10
    CPSLEEPTIME = 10

    # Initialize the chord
    def initialize(ipaddr, port)
      @node = Node.new(ipaddr, port)
      @sthr = @ffthr = @cpthr = nil
    end

    # Join another Chord ring
    def join(remip, remport)
      @node.join(remip, remport)
    end

    # start the stabilize, fix fingers, and check predecessor threads
    def start
      @sthr = Thread.new {
        loop {
          @node.stabilize
          sleep(SSLEEPTIME)
        }
      }

      @ffthr = Thread.new {
        loop {
          @node.fix_fingers
          sleep(FFSLEEPTIME)
        }
      }

      @cpthr = Thread.new {
        loop {
          @node.check_predecessor
          sleep(CPSLEEPTIME)
        }
      }
    end

    # kill the extra running threads
    def stop
      unless (@sthr.nil?)
        Thread.kill(@sthr)
      end

      unless(@ffthr.nil?)
        Thread.kill(@ffthr)
      end

      unless(@cpthr.nil?)
        Thread.kill(@cpthr)
      end

      @sthr = @ffthr = @cpthr = nil
    end

    def query(id)
      s = @node.find_succ(id)
      return([s.ipaddr, s.port, s.nodeid])
    end
  end
end
