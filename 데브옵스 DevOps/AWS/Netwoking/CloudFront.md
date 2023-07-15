# CloudFront

The AWS CDN service is called CloudFront. It serves up cached content and assets for the increased global performance of you application.

**The main components of ClouFront:**
- **adge locations:** cache endpoint
- **the origin:** original sourve of truth to be cached such as an EC2 instance, an S3 bucket, an Elastic Load Balancer or a Route 53 config
- **distribution:** the arrangement of edge locations from the origin or basically the network itself

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/8db91220-f050-4243-ba27-cf5d398fbc0b)

### To Use CloudFront...

To use Amazon CloudFront, you:
- For static files, store the definitive versions of your files in one or more origin servers. These could be Amazon S3 buckets. For you dynamically generated content that is personalized or customized,.
  
- Register your origin servers with Amazon CloudFront through a simple API call. Thsi call will return a `cloudfront.net` domain name that you can use to distribute content from your origin servers via the Amazon CloudFront service. For instance, you can register the Amazon S3 bucket `bucketname.s3.amazonaws.com` for all your dynamic content. Then, using the API or the AWS Management Console, you can create an Amazon CloudFront distribution that might return `abc123.cloudfront.net` as the distribution domain name.
  
- include the `cloudfront` domain name, or a CNAME alias that you create, in your web application, media player, or website. Each request made using the `cloudfront.net` domain name (or the CNAME you set-up) is routed to the edge location best suited to deliver the content with the highest performance. The edge location will attempt to serve the request with a local copy of the file. If a local copy is not available, Amazon CloudFront will get a copy from the origin. This copy is then available at that edge location for future requests.

## Performance

Amazon CloudFront employs a global network of edge locations and regional edge caches that cache copies of your content close to your viewers. Amazon CloudFront ensures that end-user requestsare served by the closest edge location.

As a result, viewer requests travel a short distance, improving performance for your viewers. For files not cached at the edge locations and the regional edge caches, Amazon CloudFront keeps persistent connections with your origin servers so that those files can be fetched from the origin servers as quickly as possible.

Finally, Amazon CloudFront uses additional optimizations - e.g. wider TCP initial congestion window - to provide higher performance while delivering your content to viewers.

## Key Details

- When content is cached, it is done for a certain limit called the Time To Live(TTL) Which is always in seconds.
  
- If needed, CloudFront can serve up entire websites including dynamic, static, streaming and interactive content.
  
- Requests are always routes and cached in the nearest edge location for the user, thus propagation th CDN nodes and guaranteeing best performance for future requests.
  
- There are two differnt types of distributions:
  - **Web Distribution:** web sites, normal cached items, etc
  - **RTMP:** streaming content, adobe, etc
  
- Edge locations are not just read only, They can be written to which will then return the write value back to the origin.

- Cached content can be manually invalidated or cleared beyond the TTL, but this does incur a cost.
  
- You can invalidate the distribution of certain objects or entire directories so that content is loaded directly from the origin every time. Invalidation content is also hepful when debugging if content pulled from the origin seems correct, but pulling that same content from an edge location seems incorrect.
  
- You can set up a failover for the origin by creating an origin group with two origins inside. One origin will act as the primary and the other as the secondary. CloudFront will automatically switch between the two when the primary origin fails.
  
- Amazon CloudFront delivers your content from each edge location and offers a Dedicated IP Custom SSL feature. SNI Custrom SSL works with most modern browsers.
  
- If you run PCI or HIPAA-compliant workloads and need to log usage data, you can do the following:
  - Enable CloudFront access logs.
  - Capture requests that are sent to the CloudFront API.
  
- An Origin Access Identity (OAI) is used for charing private content via CloudFront. The OAI is a virtual user that will be used to give your CloudFront distribution permission to fetch a private object from your origin. (e.q. S3 bucket).

- You can set origin groups and configuring specific origin failover options. When any of the following occur:
  - The primary origin returns an HTTP status code that you’ve configured for failover
  - CloudFront fails to connect to the primary origin
  - The response from the primary origin takes too long (times out)
  Then CloudFront routes the request to the secondary origin in the origin group.

### With S3

Amazon CloudFront with an S3 bucket as the origin can help speed up both uploads and downloads for video files.

When you configure CloudFront with an S3 bucket as the origin, CloudFront acts as a content delivery network (CDN) that caches your video files in edge locations around the world. This means that when a user requests a video file, CloudFront serves it from the edge location nearest to the user, reducing the distance and network latency between the user and the file.

For downloads, CloudFront can significantly improve the performance by delivering the video files from the nearest edge location, resulting in faster download times. Users can benefit from reduced latency and improved data transfer speeds, particularly when accessing the files from geographically distant locations.

For uploads, CloudFront can also help in certain scenarios. When you configure CloudFront with an S3 bucket as the origin, CloudFront can act as a proxy for the upload process. Instead of directly uploading the video file to the S3 bucket, the file can be uploaded to the CloudFront edge location nearest to the user. From there, CloudFront can route the upload request to the origin S3 bucket.

This approach can be beneficial in cases where the user and the S3 bucket are geographically distant. Uploading the file to the nearby CloudFront edge location can reduce the upload latency, as the data has a shorter distance to travel. However, it's worth noting that CloudFront is primarily designed for content delivery and may not provide significant improvements for all upload scenarios, especially when dealing with larger file sizes or specific network conditions.

Overall, utilizing CloudFront with an S3 bucket as the origin can improve both upload and download performance for video files by leveraging its global edge locations and caching capabilities.

### CloudFront Signed URLs and Signed Cookies

- CloudFront signed URLs and signed cookies provide the same basic functionality: they allow you to control who can access your content. These features exist because many companies that distribute content via the internet want to resrict access to documents, businesss data, media streams, or content that is intended for selected users. As an example, users who have paid a fee should be able to access private content that users on the free tier shouldn't.

- If you want to serve private content through CloudFront and you're trying to decide whether to use signed URLs or signed cookies, consider the follosing
  - Use signed URLs for the gollowing cases:
    - You want to use an RTMP distribution. Signed cookies aren't supported for RTMP distributions.
    - You want to restrict access to individual files, for example, an installation download for your application.
    - Your users are using a client (for example, a custom HTTP client) that doesn't support cookies.
  - Use signed cookies for the following cases:
    - You want to provide access to multiple restricted files. For example, all of the files for a video in HLS format or all of the files in the paid users' area of a website.
    - You don't want to change your current URLs.

## Origin Shield

Origin Shield is a <u>centralized caching layer that helps increase your cache hit ratio to reduce the load on your origin.</u> Origin Shield also decreases tour origin operating costs by collapsing request across regions so as few as on request goes to your origin per object. When enabled, CloudFront will route all origin fetches through Origin Shield and only make a request to your origin if the content is not already stored in Origin Shield's cache.

Origin Shield is ideal for **workloads with viewers that are spread across different geographical regions** or **workloads that involve just-in-time packaging** for video streaming, on-the-fly image handling, or similar processes.

Using Origin Shield in front of your origin will reduce the number of redundant origin fetches by first checking its central cache and only making a consolidated origin fetch for content not already in Origin Shield’s cache. Similarly, Origin Shield can be used in a multi-CDN architecture to reduce the number of duplicate origin fetches across CDNs by positioning Amazon CloudFront as the origin to other CDNs.

Amazon CloudFront offers Origin Shield in AWS Resions where CloudFront has a [regional cache](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowCloudFrontWorks.html#CloudFrontRegionaledgecaches). When you enable Origin Shield, you should choose the AWS Region for Origin Shield that has the lowest latency to you origin. You can use Origin Shield with origins that are in an AWS Region, ans with origins that are not in AWS.

---
reference
- https://aws.amazon.com/cloudfront/faqs/?nc1=h_ls
- https://github.com/keenanromain/AWS-SAA-C02-Study-Guide#simple-storage-service-s3
- https://puterism.com/deploy-with-s3-and-cloudfront/