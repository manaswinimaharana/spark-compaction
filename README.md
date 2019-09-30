# HDFS Compaction using Apache Spark
Small files are a common challenge in the Apache Hadoop world and when not handled with care, they can lead to a 
number of complications. The Apache Hadoop Distributed File System (HDFS) was developed to store and process large 
data sets over the range of terabytes and petabytes. However, HDFS stores small files inefficiently, leading to 
inefficient Namenode memory utilization and RPC calls, block scanning throughput degradation, and reduced application
 layer performance. Please visit[https://blog.cloudera.com/small-files-big-foils-addressing-the-associated-metadata-and-application-challenges/] for more info. 

This reusable Apache Spark based library was build to address "large # of small HDFS files" issue by compacting them 
into optimal HDFS block sized files. 

**Features**
- Can invoked multiple ways - Stand-alone Spark job, Pyspark shell, Spark-shell, custom spark applications 
- Dynamically calculates the output file size based on file format, compression and serialization
- Perform recursive compaction 
- Easy to use

**Caveats**

It should also be noted that if Avro is used as the output serialization only uncompressed and snappy compression are supported in the upstream package (spark-avro by Databricks) and the compression type will not be passed as part of the output file name.  The other option that is not supported is Parquet + BZ2 and that will result in an execution error.

**Installation**

1. Setup the development environment 

    1.1.    Clone the git project
    
    1.2.    Import the project into IDE e.g. eclipse or intellij
 
2. Build and compile
    
    2.1. Edit the pom.xml to match the CDH version of cluster 
    
    2.2. Re-compile using mvn (you can use IDE or commandline) 
     ```vim 
     mvn clean install
     ```
    This will build the target jar "spark-compaction-0.0.1-SNAPSHOT.jar" under ~/target dir
    
4. Deploy
    
    Copy the "spark-compaction-0.0.1-SNAPSHOT.jar" to the cluster.
    
    e.g. 
    ```vim 
    scp -r target/spark-compaction-0.0.1-SNAPSHOT.jar username@<edgenode-hostname>:/tmp
    ```
* Note: You can always follow enterprise standards of change control management to build and deploy the jar*

**Execution Options**

Spark-Submit
```vim
spark2-submit \
  --class org.cloudera.com.spark_compaction.HdfsCompact \
  --master local[2] \
  ${JAR_PATH}/spark-compaction-0.0.1-SNAPSHOT.jar \
  --input-path ${INPUT_PATH} \
  --output-path ${OUTPUT_PATH} \
  --input-compression [none snappy gzip bz2 lzo] \
  --input-serialization [text parquet avro] \
  --output-compression [none snappy gzip bz2 lzo] \
  --output-serialization [text parquet avro] \
  --partition-mechanism [repartition coalesce] \
  --overwrite-flag [true false
```

Example 

```spark2-submit \
  --packages com.databricks:spark-avro_2.11:4.0.0 \
  --conf spark.hadoop.avro.mapred.ignore.inputs.without.extension=false \
  --class org.cloudera.com.spark_compaction.HdfsCompact \
  --master yarn \
  --deploy-mode client \
  /tmp/spark-compaction-0.0.1-SNAPSHOT.jar \
  --input-path /user/hive/warehouse/customers \
  --output-path /user/hive/warehouse/customers_compacted5 \
  --input-compression none \
  --input-serialization parquet \
  --output-compression none \
  --output-serialization parquet \
  --partition-mechanism repartition \
  --overwrite-flag false
  ```
  
  
PySpark Shell 

```vim 
$  pyspark2 --jars <path-to-spark-compaction-0.0.1-SNAPSHOT.jar>
Python 2.7.5 (default, Jun 20 2019, 20:27:34) 
[GCC 4.8.5 20150623 (Red Hat 4.8.5-36)] on linux2
Type "help", "copyright", "credits" or "license" for more information.
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
19/09/05 12:38:02 WARN util.Utils: Service 'SparkUI' could not bind on port 4040. Attempting port 4041.
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /__ / .__/\_,_/_/ /_/\_\   version 2.3.0.cloudera5-SNAPSHOT
      /_/

Using Python version 2.7.5 (default, Jun 20 2019 20:27:34)
SparkSession available as 'spark'.
>>> from py4j.java_gateway import java_import
>>> URI = sc._gateway.jvm.java.net.URI
>>> java_import(sc._gateway.jvm,"org.cloudera.com.spark_compaction.HdfsCompact")
>>> func = sc._gateway.jvm.HdfsCompact()
>>> args= sc._gateway.new_array(sc._gateway.jvm.java.lang.String,12)
>>> args[0]='--input-path'
>>> args[1]='/tmp/compaction_input'
>>> args[2]='--output-path'
>>> args[3]='/tmp/compression_output400 '
>>> args[4]='--input-compression'
>>> args[5]='none'
>>> args[6]='--input-serialization'
>>> args[7]='text'
>>> args[8]='--output-compression'
>>> args[9]='none'
>>> args[10]='--output-serialization'
>>> args[11]='text'
>>> func.compact(args,sc._jsc) 

```


## Multiple Directory Compaction

**Sub Directory Processing**
```vim
$ hdfs dfs -du -h /landing/compaction/partition/
293.4 M  293.4 M  /landing/compaction/partition/date=2016-01-01

$ hdfs dfs -du -h /landing/compaction/partition/date=2016-01-01
48.9 M  48.9 M  /landing/compaction/partition/date=2016-01-01/hour=00
48.9 M  48.9 M  /landing/compaction/partition/date=2016-01-01/hour=01
48.9 M  48.9 M  /landing/compaction/partition/date=2016-01-01/hour=02
48.9 M  48.9 M  /landing/compaction/partition/date=2016-01-01/hour=03
48.9 M  48.9 M  /landing/compaction/partition/date=2016-01-01/hour=04
48.9 M  48.9 M  /landing/compaction/partition/date=2016-01-01/hour=05

$ hdfs dfs -du -h /landing/compaction/partition/date=2016-01-01/* | wc -l
6666
```

**Output Directory**
```vim
$ hdfs dfs -du -h /landing/compaction/partition/output_2016-01-01
293.4 M  293.4 M  /landing/compaction/partition/output_2016-01-01

$ hdfs dfs -du -h /landing/compaction/partition/output_2016-01-01/* | wc -l
3
```

**Wildcard for Multiple Sub Directory Compaction**
```vim
spark2-submit \
  --class com.github.KeithSSmith.spark_compaction.Compact \
  --master local[2] \
  ~/cloudera/jars/spark-compaction-0.0.1-SNAPSHOT.jar \
  --input-path hdfs:///landing/compaction/partition/date=2016-01-01/hour=* \
  --output-path hdfs:///landing/compaction/partition/output_2016-01-01 \
  --input-compression none \
  --input-serialization text \
  --output-compression none \
  --output-serialization text
```

### Future road map 
- Add Data Quality checks
- Add logging 
- Add additional validations, try-catch-exceptions
- Build a bash wrapper


### TL;DR
## Compression Math

At a high level this class will calculate the number of output files to efficiently fill the default HDFS block size on the cluster taking into consideration the size of the data, compression type, and serialization type.

**Compression Ratio Assumptions**
```vim
SNAPPY_RATIO = 1.7;     // (100 / 1.7) = 58.8 ~ 40% compression rate on text
LZO_RATIO = 2.0;        // (100 / 2.0) = 50.0 ~ 50% compression rate on text
GZIP_RATIO = 2.5;       // (100 / 2.5) = 40.0 ~ 60% compression rate on text
BZ2_RATIO = 3.33;       // (100 / 3.3) = 30.3 ~ 70% compression rate on text

AVRO_RATIO = 1.6;       // (100 / 1.6) = 62.5 ~ 40% compression rate on text
PARQUET_RATIO = 2.0;    // (100 / 2.0) = 50.0 ~ 50% compression rate on text
```

**Compression Ratio Formula**
```vim
Input Compression Ratio * Input Serialization Ratio * Input File Size = Input File Size Inflated
Input File Size Inflated / ( Output Compression Ratio * Output Serialization Ratio ) = Output File Size
Output File Size / Block Size of Output Directory = Number of Blocks Filled
FLOOR( Number of Blocks Filled ) + 1 = Efficient Number of Files to Store
```


### Text Compaction

**Text to Text Calculation**
```vim
Read Input Directory Total Size = x
Detect Output Directory Block Size = 134217728 => y

Output Files: FLOOR( x / y ) + 1 = # of Mappers
```

**Text to Text Snappy Calculation**
```vim
Default Block Size = 134217728 => y
Read Input Directory Total Size = x
Compression Ratio = 1.7 => r

Output Files: FLOOR( x / (r * y) ) + 1 = # of Mappers
```
To elaborate further, the following example has an input directory consisting of 9,999 files consuming 440 MB of space.  Using the default block size, the resulting output files are 146 MB in size, easily fitting into a data block.

**Input (Text to Text)**
```vim
$ hdfs dfs -du -h /landing/compaction/input | wc -l
9999
$ hdfs dfs -du -h /landing/compaction
440.1 M  440.1 M  /landing/compaction/input

440.1 * 1024 * 1024 = 461478298 - Input file size.
461478298 / 134217728 = 3.438
FLOOR( 3.438 ) + 1 = 4 files

440.1 MB / 4 files ~ 110 MB
```

**Output (Text to Text)**
```vim
$ hdfs dfs -du -h /landing/compaction/output
110.0 M  110.0 M  /landing/compaction/output/part-00000
110.0 M  110.0 M  /landing/compaction/output/part-00001
110.0 M  110.0 M  /landing/compaction/output/part-00002
110.0 M  110.0 M  /landing/compaction/output/part-00003
```


### Parquet Compaction

**Input (Parquet Snappy to Parquet Snappy)**
```vim
$ hdfs dfs -du -h /landing/compaction/input_snappy_parquet | wc -l
9999
$ hdfs dfs -du -h /landing/compaction
440.1 M  440.1 M  /landing/compaction/input_snappy_parquet

440.1 * 1024 * 1024 = 461478298 - Total input file size.
1.7 * 2 = 3.4 - Total compression ratio.
(3.4 * 461478298) / (3.4 * 134217728) = 3.438
FLOOR( 3.438 ) + 1 = 4 files

440.1 MB / 2 files ~ 110 MB
```

**Output (Parquet Snappy to Parquet Snappy)**
```vim
$ hdfs dfs -du -h /landing/compaction/output_snappy_parquet
110 M  110 M  /landing/compaction/output_snappy_parquet/part-00000.snappy.parquet
110 M  110 M  /landing/compaction/output_snappy_parquet/part-00001.snappy.parquet
110 M  110 M  /landing/compaction/output_snappy_parquet/part-00002.snappy.parquet
110 M  110 M  /landing/compaction/output_snappy_parquet/part-00003.snappy.parquet
```