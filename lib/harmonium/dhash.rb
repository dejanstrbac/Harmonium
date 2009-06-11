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
# This is an actual distributed hash table, a hash in the sense
# of Ruby, that uses Chord as its foundation.
# 
# $Id: dhash.rb 52 2006-07-24 22:06:26Z zond $
#

##
# The Distributed Hashing implementation.
#
module Harmonium
  # A distributed hash node
  class DHashNode < Node
    attr_accessor :storage

    include DRbUndumped

    ##
    # Create a new distributed hash node given the ip address, port, and
    # storage engine.  A storage engine must be some object that responds
    # at minimum to the [], []=, delete, and keys methods.  A Ruby hash
    # should do just fine.
    #
    def initialize(uri, storage)
      @storage = storage
      super(uri)
    end

    ##
    # Get a key index held on this node.
    #
    def [](key)
      return(@storage[key])
    end

    ##
    # Modify a key index held on this node.
    #
    def []=(key, val)
      return(@storage[key]=val)
    end

    ##
    # Delete a key index held on this node.
    #
    def delete(key)
      return(@storage.delete(key))
    end

    ##
    # Distributed hash notify.  In addition to doing the basic notify
    # actions defined for Harmonium::Node, when a notification is accepted
    # it transfers keys that properly belong to the notifying node to the
    # notifier.
    #
    def notify(n)
      unless (super(n))
        # do nothing if we did not accept the notification
        return(false)
      end

      # If we accepted the notification, then the keys we hold whose id's
      # are less than the notifying node's node ID are given to that
      # node.
      @storage.keys.each do |key|
        # calculate the key ID
        id = Digest::SHA1.new(key).to_s[0..MAX_LEN]
        # We move the key if the key's ID is between the notifier's node
        # (inclusive) and our node ID (noninclusive)
        if (!Util.between_oc(id, n.nodeid, @nodeid))
          n[key] = self[key]
          self.delete(key)
        end
      end
      return(true)
    end
  end

  # A distributed hash
  class DHash < Chord
    def [](key)
      owner = query(key)
      return(owner[key])
    end

    def []=(key, val)
      owner = query(key)
      owner[key] = val
      return(val)
    end
  end
end
