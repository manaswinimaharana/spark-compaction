#!/bin/bash
uid=`uuidgen`


spark2-submit \
  --class org.cloudera.com.spark_compaction.HdfsCompact \
  --master local[2] \
  /tmp/spark-compaction-0.0.1-SNAPSHOT.jar --input-path /tmp/compression_input --output-path /tmp/compression_output6 --input-compression none --input-serialization text --output-compression none --output-serialization text --partition-mechanism repartition
