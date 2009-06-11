require 'set'
require 'forwardable'

module Harmonium
  #
  # An Array class specialized at containing Harmonium::RemoteNodes (or Harmonium::Nodes)
  #
  class NodeArray
    extend Forwardable

    def_delegators :@array, :first, :size, :last, :each, :collect, :to_s, :inspect, :select, :any?, :reject, :join, :compact, :empty?
    #
    # include? will return true if the container contains a node
    # with given nodeid
    #
    def_delegators :@hash, :include?

    def initialize
      @array = []
      @hash = {}
    end
    #
    # Will return the node at index +k+ if +k+ is
    # an Integer. Will return the contained node with
    # id +k+ if +k+ is a String.
    #
    def [](k)
      case k
      when String
        @array[@hash[k].to_a.first] unless @hash[k].nil?
      when Integer
        @array[k]
      else
        raise "Unknown key type #{k}"
      end
    end
    #
    # Will insert node +v+ at index +i+
    #
    def []=(i, v)
      # delete the old index from the set in the hash
      @hash[@array[i].nodeid].delete(i) if @array[i]
      # delete the set from the hash if it is empty
      @hash.delete(@array[i].nodeid) if @array[i] && @hash[@array[i].nodeid].empty?

      # put this value in the array
      @array[i] = v

      # ensure that there is a set in the hash for this nodeid
      @hash[v.nodeid] ||= Set.new if v
      # put this value in the hash
      @hash[v.nodeid] << i if v
    end
    #
    # Will remove the node from index +k+
    # if +k+ is an Integer. Will remove all nodes
    # with nodeid +k+ if +k+ is a String.
    #
    def delete(k)
      case k
      when String
        @hash[k].each do |index|
          self[index] = nil
        end if @hash[k]
      when Integer
        self[k] = nil
      else
        raise "Unknown key type #{k}"
      end
    end
    #
    # Will clear the container
    #
    def clear
      @array.clear
      @hash.clear
      @pessimistic_distance_by_id.clear
    end
  end

end
