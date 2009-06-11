
module Harmonium

  class Chord
    attr_reader :node
    SSLEEPTIME = 10
    FFSLEEPTIME = 10
    CPSLEEPTIME = 10

    # Initialize the chord, given a node
    def initialize(node)
      @node = node
      @sthr = @ffthr = @cpthr = nil
    end

    # Join another Chord ring given its uri 
    # Chord node is running on.
    def join(uri)
      @node.join(uri)
    end

    # start the stabilize, fix fingers, and check predecessor threads
    def start
      if @sthr.nil?
        @sthr = Thread.new {
          loop {
            @node.stabilize
            sleep(SSLEEPTIME)
          }
        }
      end

      if @ffthr.nil?
        @ffthr = Thread.new {
          loop {
            @node.fix_fingers
            sleep(FFSLEEPTIME)
          }
        }
      end

      if @cpthr.nil?
        @cpthr = Thread.new {
          loop {
            @node.check_predecessor
            sleep(CPSLEEPTIME)
          }
        }
      end
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

    def query(str)
      id = Digest::SHA1.new(str).to_s[0...MAX_LEN]
      s = @node.find_succ(id)
      return(s)
    end
  end

end
