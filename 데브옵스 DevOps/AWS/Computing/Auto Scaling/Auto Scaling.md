
AWS Auto Scaling lets you build scaling plans that automate how groups of different resources respond the changes in demand. You can optimize availability, costs, or a balance of both. AWS Auto Scaling automatically creates all of the scaling policies and sets targets for you based on your prefenence.

## componets

  - **Groups**: These are logical components. A webserver group of EC2 instances, a database group of RDS instances, etc.
  - **Configuration Templates**: Groups use a template to configure and launch new instances to better match the scaling needs. You can specify imformation for the new instances like the AMI to use, the instance type, security groups, block deviced to associate with the instances, and more.
  - **Scaling Options**: Scaling Options provides serveral ways for you to scale your Auto Scaling groups. You can base the scaling trigger on the occurrence of a specified condition or on a schedule.

## Scaling options

Amazon EC2 Auto Scaling provides several ways for you to scale your Auto Scaling group.

- **Maintain current instance levels at all times:** You can configure your Auto Scaling group to maintain a specified number of running instances at all times. 
  To maintain the current instance levels, Amazon EC2 Auto Scaling performs a periodic health check on running instances within an Auto Scaling group. When Amazon EC2 Auto Scaling finds an unhealthy instance, it terminates that instance and launches a new one. 

- **Scale manually:** Manual scaling is the most basic way to scale your resources, where you specify only the change in the maximum, minimum, or desired capacity of your Auto Scaling group.

- **Scale based on a schedule:** Scailing by schedule means that scaling actions are performed automatically as a function of time and date. This is useful when you know exactly when to increase or decrease the number of instances in your group, simply because the need arises on a predictable schedule.

- **Scale based on demand:** A more advanced way to scale your resources, using dynamic scaling, lets you define a scaling policy that dynamically resizes your Auto Scaling group to meet changes in demand. 
  For example, let's say that you have a web application that currently runs on two instances and you want the CPU utilization of the Auto Scaling group to stay at around 50 percent when the load on the application changes. This method is useful for scaling in response to changing conditions, when you don't know when those conditions will change.

- **Use predictive scaling:** You can also combine predictive scaling and dynamic scaling (proactive and reactive approaches, respectively) to scale your EC2 capacity faster
  Use predictive scaling to increase the number of EC2 instances in your Auto Scaling group in advance of daily and weekly patterns in traffic flows.

## Dynamic scaling

- **Target tracking scaling:** Increase and decrease the current capacity of the group based on a Amazon CloudWatch metric and a target value. It works similar to the way that your thermostat maintains the temperature of your home—you select a temperature and the thermostat does the rest.
  - If you use a target tracking scaling policy based on a custom Amazon SQS queue metric, dynamic scaling can adjust to the demand curve of your application more effectively. 

- **Step scaling:** Increase and decrease the current capacity of the group based on a set of scaling adjustments, known as step adjustments, that vary based on the size of the alarm breach.

- **Simple scaling:** Increase and decrease the current capacity of the group based on a single scaling adjustment, with a cooldown period between each scaling activity.

---

- The following image highlights the state of an Auto scaling group. The orrange squares represent active instances. The dotted squares represent potential instances that can will be spun up whenever necessary. The minimum nuber, the maximum number, and the desired capacity of instances are all entirely configurable.

  ![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/39c77da7-5bbf-4b2c-a9a2-c4aefc659d1b)

- Auto Scaling allows you to suspend and then resume one or more of the Auto Scaling processes in your Auto Scaling Group. This can be very useful when you want to investigate a problem in you application without triggering the Auto Scaling process when making changes.

- You cannot modify a launch configuration after you've created it. If you want to change the launch configuration for an Auto Scaling group, you must create a new launch configuration and update your Auto Scaling group to inherit this new launch configuration.

---
reference
- https://docs.aws.amazon.com/ko_kr/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html
- https://aws.amazon.com/autoscaling/