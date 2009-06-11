module Harmonium

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
	return(true)
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
	return(true)
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
      return(sprintf("%0#{MAX_LEN}x", (Integer("0x" + n) + ( 1 << i )) & KEY_MASK))
    end
  end

end
