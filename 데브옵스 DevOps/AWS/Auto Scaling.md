# Auto Scaling

AWS Auto Scaling lets you build scaling plans that automate how groups of different resources respond th changes in demand. You can optimize availabilirt, costs, or a balance of both. AWS Auto Scaling automatically creates all of the scaling policies and sets targets for you based on your prefenence.

---

- Auto Scaling has three componets:
  - **Groups**: These are logical components. A webserver group of EC2 instances, a database group of RDS instances, etc.
  - **Configuration Templates**: Groups use a template to configure and launch new instances to better match the scaling needs. You can specify imformation for the new instances like the AMI to use, the instance type, security groups, block deviced to associate with the instances, and more.
  - **Scaling Options**: Scaling Options provides serveral ways for you to scale your Auto Scaling groups. You can base the scaling trigger on the occurrence of a specified condition or on a schedule.

- The following image highlights the state of an Auto scaling group. The orrange squares represent active instances. The dotted squares represent potential instances that can will be spun up whenever necessary. The minimum nuber, the maximum number, and the desired capacity of instances are all entirely configurable.
