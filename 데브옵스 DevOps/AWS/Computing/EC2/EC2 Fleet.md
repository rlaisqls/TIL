# EC2 Fleet

An EC2 Fleet contains the configuration information to launch a fleet—or group—of instances. In a single API call, a fleet can launch multiple instance types across multiple Availability Zones, using the On-Demand Instance, Reserved Instance, and Spot Instance purchasing options together. Using EC2 Fleet, you can:

- Define separate On-Demand and Spot capacity targets and the maximum amount you’re willing to pay per hour

- Specify the instance types that work best for your applications

- Specify how Amazon EC2 should distribute your fleet capacity within each purchasing option

You can also set a maximum amount per hour that you’re willing to pay for your fleet, and EC2 Fleet launches instances until it reaches the maximum amount.

When the maximum amount you're willing to pay is reached, the fleet stops launching instances even if it hasn’t met the target capacity.

The EC2 Fleet attempts to launch the number of instances that are required to meet the target capacity specified in your request. If you specified a total maximum price per hour, it fulfills the capacity until it reaches the maximum amount that you’re willing to pay. The fleet can also attempt to maintain its target Spot capacity

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/9e284444-791b-409d-90a0-6c3f6e44b308)

You can specify an unlimited number of instance types per EC2 Fleet. Those instance types can be provisioned using both On-Demand and Spot purchasing options. You can also specify multiple Availability Zones, specify different maximum Spot prices for each instance, and choose additional Spot options for each fleet. Amazon EC2 uses the specified options to provision capacity when the fleet launches.

While the fleet is running, if Amazon EC2 reclaims a Spot Instance because of a price increase or instance failure, EC2 Fleet can try to replace the instances with any of the instance types that you specify. This makes it easier to regain capacity during a spike in Spot pricing. You can develop a flexible and elastic resourcing strategy for each fleet. For example, within specific fleets, your primary capacity can be On-Demand supplemented with less-expensive Spot capacity if available.

If you have Reserved Instances and you specify On-Demand Instances in your fleet, EC2 Fleet uses your Reserved Instances. For example, if your fleet specifies an On-Demand Instance as c4.large, and you have Reserved Instances for c4.large, you receive the Reserved Instance pricing.

There is no additional charge for using EC2 Fleet. You pay only for the EC2 instances that the fleet launches for you.

---

## Spot Fleet vs. Spot Instances

- The Spot Fleet selects the Spot Instance pools that meet your needs and launches Spot Instances to meet the target capacity for the fleet. By default, Spot Fleets are set to maintain target capacity by launching replacement instances after Spot Instances in the fleet are terminated.

- A spot instance generates a single request for a specific instance in a specific available area. Instead of requesting a single instance type, you can use a spotlet to request different instance types that meet your requirements. If the CPU and RAM are close enough for heavy workloads, it's okay to have many instance types.

- This allows you to use spotplits to distribute instance costs across zones and instance types. In addition to the low disruption rates already mentioned, spot fleets can greatly enhance the system. You can also run an on-demand cluster to provide additional protection capacity.
  
![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/7a0e1e6a-eb39-49b7-bbf0-3a28d5fa4ef3)

- With spot fleets, you can also apply a custom weighting to each instance type. Weighting tells the spot fleet request what total capacity we care about. As a simple example, say we would like a total capacity of 10GB of RAM, and we select two instance types, one that has 2GB and one that has 4GB of RAM.




---

reference
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-fleet.html
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-fleet.html