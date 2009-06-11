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
# This is the storage engine for a distributed hash table based on the
# Madeleine object persistence layer.
# 
# $Id: madeleine_storage.rb 46 2006-03-28 06:47:29Z dido $
#
require 'rubygems'
require_gem 'madeleine'

module Harmonium
  module MadeleineStorage
    ##
    # Generic command object.  This is intended to be used to send queries
    # and commands to the madeleine object.
    #
    class Command
      def initialize(method, *args, &block)
        @method = method
        @args = args
        @block = block
      end

      def execute(system)
        return(system.send(@method, *@args, &@block))
      end

    end

    class Storage
      attr_accessor :madeleine, :snapthread

      def initialize(dbname)
        @data = Hash.new
        @madeleine = SnapshotMadeleine.new(dbname) { @data }
        @snapthread = nil
      end

      ##
      # Manually take a snapshot of the Madeleine system.
      #
      def take_snapshot
        @madeleine.take_snapshot
      end

      ##
      # Create a thread that will automatically take a snapshot every
      # +interval+ seconds.
      #
      def snapthread(interval=30)
        @snapthread = Thread.new(@madeleine) do |m|
          loop do
            sleep(interval)
            m.take_snapshot
          end
        end
        return(self)
      end

      ##
      # Get a value given +key+ inside this engine.
      #
      def [](key)
        return(@madeleine.execute_query(Command.new(:[], key)))
      end

      ##
      # Modify a key/value pair held in this engine.
      #
      def []=(key, val)
        return(@madeleine.execute_command(Command.new(:[]=, key, val)))
      end

      ##
      # Delete a key/value pair held on this node.
      #
      def delete(key)
        return(@madeleine.execute_command(Command.new(:delete, key)))
      end

      ##
      # List all the keys held on this node.
      #
      def keys
        return(@madeleine.execute_query(Command.new(:keys)))
      end

    end

  end

end
