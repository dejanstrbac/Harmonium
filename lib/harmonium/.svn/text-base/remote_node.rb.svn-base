module Harmonium
  #
  # Encapsulates a remote Node. Allways created locally
  # so that the initialization is quick, and allways sent
  # marshalled so that the most important data is quickly
  # accessed from the remote side.
  #
  # Has some extra complexity to handle the 'intelligence' 
  # of druby that automagically calls local methods instead
  # of remote when a remote reference to a local object is
  # detected.
  #
  class RemoteNode
    
    # The synthetic coordinates of the Node behind this RemoteNode
    attr_accessor :coordinates
    # The Node that is managing this RemoteNode at the moment
    attr_accessor :holder

    #
    # Initialize by remembering the nodeid, coordinates, 
    # +node+, object_id and an uri for the +node+.
    #
    # Since the given +node+ is always the holder (it so happens
    # that a RemoteNode is only initialized by its holder)
    # we can remember that as well.
    #
    def initialize(node)
      @node = node
      @nodeid = @node.nodeid
      @coordinates = @node.coordinates
      @holder = node
      @ref = @node.object_id
      @uri = @node.uri
      @remote_node = nil
    end

    def pretty_print(p)
      if Harmonium::Node === @node
        c = self.clone
        c.instance_variable_set(:@node, c.instance_variable_get(:@node).to_s)
        p.pp(c)
      else
        super
      end
    end

    def inspect
      if Harmonium::Node === @node
        c = self.clone
        c.instance_variable_set(:@node, c.instance_variable_get(:@node).to_s)
        c.inspect
      else
        super
      end
    end
    
    #
    # Optimize by calling the node itself if possible
    #
    # If the return value is something that knows about
    # a holder, give it the same holder we have.
    #
    # Also, rename the method and add extra data to the params
    # if we are calculating coordinates, and fetch the extra
    # data received.
    #
    def method_missing(*args)
      args_to_use = prepare_arguments(args)

      rval = nil
      time_delta = time do 
        rval = delegate(*args_to_use)
      end

      process_return_value(rval, time_delta)
    end

    # Only save the nodeid and remote_node
    def _dump(lv)
      begin
        Marshal.dump([@nodeid, @coordinates, @uri, @ref])
      rescue Exception => e
        puts e
        pp e.backtrace
      end
    end

    # Restore the nodeid and the remote node
    def self._load(s)
      begin
        nodeid, coordinates, uri, ref = Marshal.load(s) 
        it = self.allocate
        it.instance_variable_set(:@nodeid, nodeid)
        it.instance_variable_set(:@coordinates, nodeid)
        it.instance_variable_set(:@uri, uri)
        it.instance_variable_set(:@ref, ref)
        if DRb.here?(uri)
          it.instance_variable_set(:@node, ObjectSpace._id2ref(ref))
          it.instance_variable_set(:@remote_node, nil)
        else
          it.instance_variable_set(:@node, nil)
          it.instance_variable_set(:@remote_node, DRbObject.new_with_uri(uri))
        end
        it
      rescue Exception => e
        puts e
        pp e.backtrace
      end
    end

    def nodeid
      if Node.validate_nodeid?
        uri = @node.nil? ? @remote_node.__drburi : @node.uri
        raise NodeError.new(false), "#{@nodeid} is not the hash of #{uri}" if Digest::SHA1.new(uri).to_s[0..MAX_LEN] != @nodeid
      end
      @nodeid
    end

    protected
    
    #
    # Process our return
    #
    def process_return_value(rval, time_delta)
      if Node.calculate_coordinates? && holder.nodeid != nodeid
        rval, self.coordinates, perform_time = rval
        time_delta -= perform_time
        holder.update_coordinates(self.coordinates, 
                                  calculate_distance(:time_delta => time_delta,
                                                     :self_nodeid => self.nodeid,
                                                     :holder_nodeid => holder.nodeid))
        prepare_return_value(rval)
      else
        prepare_return_value(rval)
      end
    end

    #
    # Prepare our arguments, changing the name of the called
    # method and adding extra arguments if needed
    #
    def prepare_arguments(args)
      args_to_use = args.clone

      if Node.calculate_coordinates? && @holder.nodeid != @nodeid
        args_to_use.unshift("_coord_#{args_to_use.shift}".to_sym)
        args_to_use << [holder.nodeid, holder.coordinates]
      end

      args_to_use
    end

    #
    # Get the time it took to run block
    #
    def time(&block)
      t = Time.new
      yield
      Time.new - t
    end

    #
    # Delegate a set of +args+ to
    # either our node or our remote_node
    #
    def delegate(*args)
      unless @node.nil?
        @node.send(*args)
      else
        @remote_node.send(*args)
      end
    end

    #
    # Make sure we act the same even if our remote node
    # is actually local, and that we set its holder
    # if needed.
    #
    def prepare_return_value(rval)
      begin
        rval = rval.clone
      rescue
        # /moo
      end

      if rval.respond_to?(:holder=)
        rval.holder = self.holder
      end

      rval
    end

    #
    # Override this in test classes to simplify testing
    # synthetic coordinates.
    #
    # See NodeTest::DistancedRemoteNode.
    #
    def calculate_distance(options)
      options[:time_delta]
    end

  end
end 
