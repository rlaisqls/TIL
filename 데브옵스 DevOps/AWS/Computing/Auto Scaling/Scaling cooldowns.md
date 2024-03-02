
- After your Auto Scaling group launches or terminates instances, it waits for a cooldown period to end before any further scaling activities initiated by simple scaling policies can start.
  
- The intention of the cooldown period is **to prevent your Auto Scaling group from launching or terminating additional instances before the effects of previous activities are visible.**

- Suppose, for example, that a simple scaling policy for CPU utilization recommends launching two instances. EC2 Auto Scaling launches two instances and then pauses the scaling activities until the cooldown period ends.
    After the cooldown period ends any scaling activities initiated by simple scaling policies can resume. If CPU utilization breaches the alarm high threshold again, the Auto Scaling group scales out again, and the cooldowm period takes effect again.

## Considerations

The follwing considerations apply when working with simple scaling policies and scaling cooldowns:

- Target tracking and step scaling policies can initiate a scale-out activity immediarely without waiting for the cooldown period to end. Instead, whenever your Auto Scalign group launched instances, the indivisual instances have a warm-up period. For more information, see [Set the default instance warmup for an Auto Scaling group](https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-default-instance-warmup.html).

- When a scheduled action starts at the scheduled time, it can also initiate a scaling activity immediatly without waiting for the cooldown period to end.

- If an instance becomes unhealthy, EC2 Auto Scaling does not wait for the cooldown period to end before replacing the unhealthy instance.

- When multiple instances launch or terminate, the cooldown period (either the default cooldown or the scaling policy-specific cooldown) takes effect starting when the last instance finished launching or terminating.

- When you manually scale your Auto Scaling group, the default is not to wait for a cooldown to end. However, you can override this behavior and honor the default cooldown when you use the AWS CLI or an SDK to manually scale.

- By default, Elastic Load Balancing waits 300 seconds to complete the deregistration (connection draining) process. If the group is behind an Elastic Load Balancing load balancer, it will wait for the terminating instances to deregister before starting the cooldown period.

---
reference
- https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-scaling-cooldowns.html