#!/bin/bash
uid=`uuidgen`

jarPath=${1}
ip=${2}
op=${3}
ic=${4}
is=${5}
oc=${6}
os=${7}
pm=${8}




spark2-submit \
  --class org.cloudera.com.spark_compaction.HdfsCompact \
  --master local[2] \
  ${jarPath} \
  --input-path ${ip} \
  --output-path ${op} \
  --input-compression ${ic} \
  --input-serialization ${is} \
  --output-compression ${oc} \
  --output-serialization ${os} \
  --partition-mechanism ${pm}
