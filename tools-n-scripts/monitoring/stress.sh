java -jar -Xmx1024m  \
  -Dorg.opennms.rrd.queuing.writethreads=1 \
  -Dstresstest.filecount=6000 \
  -Dstresstest.modulus=1000 \
  -Dstresstest.threadcount=10 \
  -Dstresstest.maxupdates=1000 \
  -Dstresstest.updatefile=./classes/stress-test-simple.txt \
  -Dstresstest.file=/Users/indigo/rrd-stress/ \
  opennms-rrd-stresser-1.11.0-SNAPSHOT-jar-with-dependencies.jar
