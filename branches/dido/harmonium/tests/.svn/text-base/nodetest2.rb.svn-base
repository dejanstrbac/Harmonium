
require 'chord'

n1 = Chord::Node.new("127.0.0.1", 12288)
n1.stabilize
0.upto(32) {
  n1.fix_fingers
}

n2 = Chord::Node.new("127.0.0.1", 12289)
n2.join("127.0.0.1", 12288)

puts("stabilizing #{n2.nodeid}")
n2.stabilize
puts("stabilizing #{n1.nodeid}")
n1.stabilize

print "node1\n"
print "nid = #{n1.nodeid}\n"
print "succ = #{n1.succ.nodeid}\n"
print "pred = #{n1.succ.nodeid}\n"
print "node2\n"
print "nid = #{n2.nodeid}\n"
print "succ = #{n2.succ.nodeid}\n"
print "pred = #{n2.pred.nodeid}\n"

0.upto(32) {
  n1.fix_fingers
}
0.upto(32) {
  n2.fix_fingers
}

n3 = Chord::Node.new("127.0.0.1", 12290)
puts("Created node 3: #{n3.nodeid}")
n3.join("127.0.0.1", 12288)

0.upto(32) {
  n1.fix_fingers
}
0.upto(32) {
  n2.fix_fingers
}
0.upto(32) {
  n3.fix_fingers
}

n3.stabilize
n2.stabilize
n1.stabilize

n4 = Chord::Node.new("127.0.0.1", 12991)
puts("Created node 4: #{n4.nodeid}")
n4.join("127.0.0.1", 12289)

n4.stabilize
n3.stabilize
n2.stabilize
n1.stabilize

print "node1\n"
print "nid = #{n1.nodeid}\n"
print "succ = #{n1.succ.nodeid}\n"
print "pred = #{n1.pred.nodeid}\n"
print "node2\n"
print "nid = #{n2.nodeid}\n"
print "succ = #{n2.succ.nodeid}\n"
print "pred = #{n2.pred.nodeid}\n"
print "node3\n"
print "nid = #{n3.nodeid}\n"
print "succ = #{n3.succ.nodeid}\n"
print "pred = #{n3.pred.nodeid}\n"
print "node4\n"
print "nid = #{n4.nodeid}\n"
print "succ = #{n4.succ.nodeid}\n"
print "pred = #{n4.pred.nodeid}\n"
