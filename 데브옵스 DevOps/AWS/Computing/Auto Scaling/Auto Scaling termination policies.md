# Auto Scaling termination policies

When Amazon EC2 Auto Scaling terminates instances, it attempts to maintain balance across the Availability Zones that are used by your Auto Scaling group. Maintaining balance across Availability Zones takes precedence over termination policies.

If one Availability Zone has more instances than the other Availability Zones that are used by the group, Amazon EC2 Auto Scaling applies the termination policies to the instances from the imbalanced Availability Zone. If the Availability Zones used by the group are balanced, Amazon EC2 Auto Scaling applies the termination policies across all of the Availability Zones for the group.

The default termination policy applies multiple termination criteria before selecting an instance to terminate. When Amazon EC2 Auto Scaling terminates instances, it first determines which Availability Zones have the most instances, and it finds at least one instance that is not protected from scale in. Within the selected Availability Zone, the following default termination policy behavior applies:

1. Determine whether any of the instances eligible for termination use the oldest launch template or launch configuration:
    - **[For Auto Scaling groups that use a launch template]**
        - Determine whether any of the instances use the oldest launch template, unless there are instances that use a launch configuration. Amazon EC2 Auto Scaling terminates instances that use a launch configuration before it terminates instances that use a launch template.
    - **[For Auto Scaling groups that use a launch configuration]**
        - Determine whether any of the instances use the oldest launch configuration.
        - After applying the preceding criteria, if there are multiple unprotected instances to terminate, determine which instances are closest to the next billing hour. If there are multiple unprotected instances closest to the next billing hour, terminate one of these instances at random.
        - Note that terminating the instance closest to the next billing hour helps you maximize the use of your instances that have an hourly charge. Alternatively, if your Auto Scaling group uses Amazon Linux, Windows, or Ubuntu, your EC2 usage is billed in one-second increments. For more information, see Amazon EC2 pricing
2. After applying the preceding criteria, if there are multiple unprotected instances to terminate, determine which instances are closest to the next billing hour.
    - If there are multiple unprotected instances closest to the next billing hour, terminate one of these instances at random.

## Use different termination policies

To specify the termination criteria to apply before Amazon EC2 Auto Scaling chooses an instance for termination, you can choose from any of the following predefined termination policies:

1. `Default`
   - Terminate instances according to the default termination policy. This policy is useful when you want your Spot allocation strategy evaluated before any other policy, so that every time your Spot instances are terminated or replaced, you continue to make use of Spot Instances in the optimal pools.
   - It is also useful, for example, when you want to move off launch configurations and start using launch templates.

2. `AllocationStrategy`
   - Terminate instances in the Auto Scaling group to align the remaining instances to the allocation strategy for the type of instance that is terminating (either a Spot Instance or an On-Demand Instance).
   - This policy is useful when your preferred instance types have changed.
     - If the Spot allocation strategy is `lowest-price`, you can gradually rebalance the distribution of Spot Instances across your N lowest priced Spot pools.
     - If the Spot allocation strategy is `capacity-optimized`, you can gradually rebalance the distribution of Spot Instances across Spot pools where there is more available Spot capacity.
   - You can also gradually replace On-Demand Instances of a lower priority type with On-Demand Instances of a higher priority type.

3. `OldestLaunchTemplate`
   - Terminate instances that have the oldest launch template. With this policy, instances that use the noncurrent launch template are terminated first, followed by instances that use the oldest version of the current launch template. This policy is useful when you're updating a group and phasing out the instances from a previous configuration.

4. `OldestLaunchConfiguration`
   - Terminate instances that have the oldest launch configuration. This policy is useful when you're updating a group and phasing out the instances from a previous configuration. With this policy, instances that use the noncurrent launch configuration are terminated first.

5. `ClosestToNextInstanceHour`
   - Terminate instances that are closest to the next billing hour. This policy helps you maximize the use of your instances that have an hourly charge. (Only instances that use Amazon Linux, Windows, or Ubuntu are billed in one-second increments.)

6. `NewestInstance`
   - Terminate the newest instance in the group. This policy is useful when you're testing a new launch configuration but don't want to keep it in production.

7. `OldestInstance`
   - Terminate the oldest instance in the group. This option is useful when you're upgrading the instances in the Auto Scaling group to a new EC2 instance type. You can gradually replace instances of the old type with instances of the new type.

---
reference
- https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-termination-policies.html
