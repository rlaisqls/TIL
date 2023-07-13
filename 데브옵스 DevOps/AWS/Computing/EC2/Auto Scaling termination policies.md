# Auto Scaling termination policies

When Amazon EC2 Auto Scaling terminates instances, it attempts to maintain balance across the Availability Zones that are used by your Auto Scaling group. Maintaining balance across Availability Zones takes precedence over termination policies. If one Availability Zone has more instances than the other Availability Zones that are used by the group, Amazon EC2 Auto Scaling applies the termination policies to the instances from the imbalanced Availability Zone. If the Availability Zones used by the group are balanced, Amazon EC2 Auto Scaling applies the termination policies across all of the Availability Zones for the group.

The default termination policy applies multiple termination criteria before selecting an instance to terminate. When Amazon EC2 Auto Scaling terminates instances, it first determines which Availability Zones have the most instances, and it finds at least one instance that is not protected from scale in. Within the selected Availability Zone, the following default termination policy behavior applies:

- Determine whether any of the instances eligible for termination use the oldest launch template or launch configuration:
    - **[For Auto Scaling groups that use a launch template]**
        Determine whether any of the instances use the oldest launch template, unless there are instances that use a launch configuration. Amazon EC2 Auto Scaling terminates instances that use a launch configuration before it terminates instances that use a launch template.
    - **[For Auto Scaling groups that use a launch configuration]**
        Determine whether any of the instances use the oldest launch configuration.
        After applying the preceding criteria, if there are multiple unprotected instances to terminate, determine which instances are closest to the next billing hour. If there are multiple unprotected instances closest to the next billing hour, terminate one of these instances at random.
        Note that terminating the instance closest to the next billing hour helps you maximize the use of your instances that have an hourly charge. Alternatively, if your Auto Scaling group uses Amazon Linux, Windows, or Ubuntu, your EC2 usage is billed in one-second increments. For more information, see Amazon EC2 pricing.

---
reference
- https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-termination-policies.html
