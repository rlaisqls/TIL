# Lambda 

AWS LAmbda leys you run code without provisioning or managing servers. You pay only for the compute time you consume. With Lambda, you can run code for virtually any type of application or backend service - all with zero administration. You upload your code and Lambda takes care of everything required to run and scale your code with high availability. You can set up your code to be automatically triggered from other AWS services or be called directly from any web or mobile app.

---

- Lambda is a compute service where you upload your code as a function and AWS provisions the necessary details underneath the function so that the function executes successfully.

- AWS Lambda is the ultimate abstraction layer. You only worry about code, AWS does everything else.

- Lambda supports Go, Python, C#, PowerShell, Node.js, and Java

- Each Lambda function maps to one request. Lambda scales horizontally automatically.

- Lambda is priced on the number of requests and the first one million are free. Each million afterwards is $0.20.

- Lambda is also priced on the runtime of your code, rounded up to the nearest 100mb, and the amount of memory your code allocates.

- Lambda works globally.

- Lambda functions can trigger other Lambda functions.

- You can use Lambda as an event-driven service that executes based on changes in your AWS ecosystem.

- You can also use Lambda as a handler in response to HTTP events via API calls over the AWS SDK or API Gateway.

- When you create or update Lambda functions that use environment variables, AWS Lambda encrypts them using the AWS Key Management Service. When your Lambda function is invoked, those values are decrypted and made available to the Lambda code.

- The first time you create or update Lambda functions that use environment variables in a region, a default service key is created for you automatically within AWS KMS. This key is used to encrypt environment variables. However, if you wish to use encryption helpers and use KMS to encrypt environment variables after your Lambda function is created, you must create your own AWS KMS key and choose it instead of the default key.

- To enable your Lambda function to access resources inside a private VPC, you must provide additional VPC-specific configuration information that includes VPC subnet IDs and security group IDs. AWS Lambda uses this information to set up elastic network interfaces (ENIs) that enable your function to connect securely to other resources within a private VPC.

- AWS X-Ray allows you to debug your Lambda function in case of unexpected behavior.

## Lambda@Edge

- You can use Lambda@Edge to allow your Lambda functions to customize the content that CloudFront delivers.

- It adds compute capacity to your CloudFront edge locations and allows you to execute the functions in AWS locations closer to your application's viewers. The functions run tin response to CloudFront events, withour provisioning or managing servers. You can use Lambda functions to change CloudFront requests and responses at the following points:
  - After CloudFront receives a request from a viewer (viewer request)
  - Before CloudFront forwards the request to the origin (origin request)
  - After CloudFront receives the response from the origin (origin response)
  - Before CloudFront forwards the response to the viewer (viewer response)
    ![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/54e7a0eb-ffa9-4fa2-a3b3-9fb70b9e7562)

- You'd use Lambda@Edge to simplify and reduce origin infrastructure.