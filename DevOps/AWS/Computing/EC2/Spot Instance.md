<img width="839" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/d6216964-7b4a-4eab-8c34-f21af466f893">

## Spot Instance

A Spot Instance is a type of AWS EC2 instance that allows you to use spare Amazon EC2 computing capacity at a significantly reduced cost compared to on-demand instances. You bid for this unused capacity, and when your bid meets or exceeds the current Spot price, your instance runs.

However, your Spot Instance can be interrupted and terminated if the Spot price goes higher than your bid or if Amazon needs the capacity back.

<img width="430" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/543ba9be-42a6-41fa-9c0e-f4447907e3ef">

## Spot Block

Spot blocks are designed not to be interrupted and will run continuously for the duration you select, independent of Spot market price.

In rare situations, Spot blocks may be interrupted due to Amazon Web Services capacity needs. In these cases, we will provide a two-minute warning before we terminate your instance, and you will not be charged for the affected instance(s).

## Spot fleet

A Spot Fleet is a collection or fleet of Spot Instances and/or Spot Blocks. It allows you to request a combination of instance types, across multiple Availability Zones, and can help in managing capacity, costs, and performance based on your application's needs.

Spot Fleets can automatically request Spot Instances or Spot Blocks to maintain the desired capacity within the defined constraints and budget. They can also fall back to on-demand instances if Spot capacity is not available within your specified criteria.

---
reference
- https://docs.aws.amazon.com/ko_kr/AWSEC2/latest/UserGuide/using-spot-instances.html
- https://docs.aws.amazon.com/ko_kr/AWSEC2/latest/UserGuide/spot-requests.html
- https://aws.amazon.com/ko/blogs/aws/new-ec2-spot-blocks-for-defined-duration-workloads/