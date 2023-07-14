# Kinesis

Amazon Kinesis makes it easy to collect, process, and analyze real-time, streaming data so you can get timely insights and reacy quickly to new information. With Amazon Kinesis, you can ingest real-time data such as video, audio, application logs, website clickstreams, and IoT telemetry data for machine learning, analytics, and other applications. Amazon Kinesis enables you to process and analyze daata as it arrives and respond instantly instread of having to wait until all your data is collected before the processing can begin.

---

- Amazon Kinesis makes it easy to load and analyze the large volumes of data entering AWS.

- Kinisis is used for processing real-time data streams (data that is generated continuously) from devices constantly sending data into AWS so that said data can be collected and analyzed.

- It is a fully managed service that automatically scales to match the throuput of your data before loading it, minimizing the amount of storage used at the destination and increading security.

- There are three different types of Kinesis:
    - **Kinesis Streams**
      - Kinesis Streams works where the data producers stream their data into Kinesis Streams which can retain the data from one day up until 7 days. Once inside Kinesis Streams, the data is contained within shards.
      - Kinesis Streams can continously capture and store terabytes of data per hour from hundreds of thousands of sources such as website clickstreams, financial transactinos, cocial media feeds, IT logs, and location-tracking events. For example: puchase requests from a large online store like Amazon, stock prices, Netflix content, Twitch content, online gaming data, Uber positioning and directions, etc.

    - **Kinesis Firehose**
      - Amazon Kinesis Firehose is the easiesy way to load streaming data into data stores and analytics tools. When data is streamed into Kinesis Firehose, there is no persistent storage there to hold onto it. The data has to be analyzed as it comes in so it's optional to have Lambda functinos inside your Kinesis Firehose. Once processed, you send the data elsewhere.
      - Kinesis Firehose can capture, transform, and load streaming data into Amazon S3, Amazon Redshift, Amazon Elasticsearch Service, and Splunk, enabling near real-time analytics with existing business intellijgence tools and dashboards you're already using today.

    - **Kinesis Analytics**
      - Kinesis Analytics work with both Kinesis Streams and Kinesis Firehose and can analyze data on the fly. The data within Kinesis Analytics also gets sent elsewhere once it is finished processing. It analyzes your data inside of the Kinesis service itselt.

- artition keys are used with Kinesis so you can organize data by shard. This way, input from a particular device can be assigned a key that will limit its destination to a specific shard.

- Partition keys are useful if you would like to maintain order within your shard.

- Consumers, or the EC2 instances that read from Kinesis Streams, can go inside the shards to analyze what is in there. Once finished analyzing or parsing the data, the consumers can then pass on the data to a number of places for storage like a DB or S3.

- The total capacity of a Kinesis stream is the sum of data within its constituent shards.

- You can always increase the write capacity assigned to your shard table.

