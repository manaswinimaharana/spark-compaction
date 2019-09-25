[systest@nightly516-1 ~]$ cat run.sh 
#!/bin/bash
uid=`uuidgen`
appName=${9}

# Example
# bash run.sh /tmp/spark-compaction-0.0.1-SNAPSHOT.jar /tmp/compression_input/ /tmp/output17 none text none text repartition testApp

#bash run.sh /tmp/spark-compaction-0.0.1-SNAPSHOT.jar /user/hive/warehouse/customers/ /user/hive/warehouse/customers_compaction/ none parquet snappy parquet repartition customers


echo "The log is directed to /tmp/${appName}_${uid}.out"
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1> /tmp/${appName}_${uid}.out 2>&1

jarPath=${1}
ip=${2}
op=${3}
ic=${4}
is=${5}
oc=${6}
os=${7}
pm=${8}
appName=${9}

echo "-----Application Name-Uid::: ${appName}-${uid} --------"
echo "Input File Path:: " ${ip}
echo "Temp Output File Path:: " ${op}
echo "Input Compression:: " ${ic}
echo "Input Serialization:: " ${is}
echo "Output Compression:: " ${oc}
echo "Output Serialization:: " ${os}
echo "Partition Mechanism:: " ${pm}

if ! `hdfs dfs -test -e ${ip}`;
 then
    echo "${ip} does not exists on HDFS"
    exit 1
fi

if ! `hdfs dfs -test -d ${ip}`;
 then
    echo "${ip} is not a directory"
    exit 1
fi

if `hdfs dfs -test -e ${op}`;
 then
    echo "${op} directory already exists"
    exit 1
fi

prevFilecount=`hdfs dfs -count ${ip} | awk '{print $2}'`

echo "File count before compaction::" ${prevFilecount}

ipSize=`hdfs dfs -du -s -h ${ip} | tail -1 | awk '{print $1}'`

echo "Input file size::" ${ipSize}

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

if [ $? -ne 0 ]; then
  echo "Spark job failed /tmp/bck${ip} failed!!"
  exit 1
fi

opSize=`hdfs dfs -du -s -h ${op} | tail -1 | awk '{print $1}'`  

echo "Output file size::" ${opSize} 

if [ "${ic}" == "${oc}" ]  && [ "${ipSize}" == "${opSize}" ] ; 
 then
 echo "Validatation failed !! compaction is aborted for ${ip}"
 exit 1
fi 

echo "Validation Completed Successfully!!!"

`hdfs dfs -mkdir -p /tmp/bck${ip}`

if [ $? -ne 0 ]; then
  echo "Creation of HDFS temp directory /tmp/bck${ip} failed!!"
  exit 1
fi  

`hdfs dfs -mv ${ip}/* /tmp/bck${ip}`

if [ $? -ne 0 ]; then
  echo "Moving ${ip} to /tmp/bck${ip} failed!!"
  exit 1
fi

`hdfs dfs -mv ${op}/* ${ip}`
if [ $? -ne 0 ]; then
  echo "Moving ${op} to ${ip} failed!!"
  exit 1
fi

`hdfs dfs -rm -r /tmp/bck/${ip}`
if [ $? -ne 0 ]; then
  echo "Removing /tmp/bck${ip} failed!!"
  exit 1
fi

`hdfs dfs -rm -r ${op}`
if [ $? -ne 0 ]; then
  echo "Removing ${op}  failed!!"
  exit 1
fi
  
after_filecount=`hdfs dfs -count ${ip} | awk '{print $2}'`

echo "File count after compaction::" ${after_filecount}
