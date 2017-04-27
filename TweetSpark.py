# Nos conectamos y descargamos los tweets

from pyspark import SparkContext
from pyspark.streaming import StreamingContext
from pyspark.sql import SQLContext

sc = SparkContext(master = "spark://datactive-VirtualBox:8088")

ssc = StreamingContext(sc, 10)
sqlContext = SQLContext(sc)

socket_stream = ssc.socketTextStream("127.0.0.1", 8088)

lines = socket_stream.window( 20 )

# Con Spark agrupamos por Hastag y contamos el número de tweets por hastag

from collections import namedtuple
fields = ("tag", "count" )
Tweet = namedtuple( 'Tweet', fields )

( lines.flatMap( lambda text: text.split( " " ) )
  .filter( lambda word: word.lower().startswith("#") )
  .map( lambda word: ( word.lower(), 1 ) )
  .reduceByKey( lambda a, b: a + b )
  .map( lambda rec: Tweet( rec[0], rec[1] ) )
  .foreachRDD( lambda rdd: rdd.toDF().registerTempTable("tweets") ) ) 

ssc.start() 
ssc.awaitTermination()