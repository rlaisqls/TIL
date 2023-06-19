# DR strategies

DR is a crucial part of your Business Continuity Plan. How can we architect for disaster recovery (DR), which is the process of preparing for and recovering from a disaster?

Because a disaster event can potentially take down your workload, your objective for DR should be bringing your workload back up or avoiding downtime altogether. We use the following objectives:

- Recovery time objective (RTO): The maximum acceptable delay between the interruption of service and restoration of service. This determines an acceptable length of time for service downtime.
- Recovery point objective (RPO): The maximum acceptable amount of time since the last data recovery point. This determines what is considered an acceptable loss of data.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/662360ab-2732-42a6-9043-13683496de51)

For RTO and RPO, lower numbers represent less downtime and data loss. However, lower RTO and RPO cost more in terms of spend on resources and operational complexity. Therefore, you must choose RTO and RPO objectives that provide appropriate value for your workload.

## DR strategies

## Backup and restore

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/eddbe7fb-1f4b-42e5-952b-c4975693ee08)

- Lower priority usecases
- Provision all AWS resources after event
- Restore backups after event
- cost: $

- Backups are created in the same Region as their source and are also copied to another Region. This gives you the most effective protection from disasters of any scope of impact. 

- The backup and recovery strategy is considered the least efficient for RTO. However, you can use AWS resources like Amazon EventBridge to build serverless automation, which will reduce RTO by improving detection and recovery

## Pilot Light

<img width="755" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/e40ffc10-6d7d-45d5-a113-0591daf76c41">

- Data live
- Services idle
- Provision some AWS resources and sacle after event
- cost: $$

- With the pilot light strategy, the data is live, but the services are idle.
    - Live data means the data stores and databases are up-to-date (or nearly up-to-date) with the active Region and ready to service read operations.
- But as with all DR strategies, backups are also necessary. In the case of disaster events that wipe out or corrupt your data, these backups let you “rewind” to a last known good state.

## Warm Standby

<img width="748" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/24ab88d8-88f0-45be-9b6b-3a102d0af317">

- Always running, but smaller
- Business critical
- Scale AWS resources after event
- cost: $$$

- Like the pilot light strategy, the warm standby strategy maintains live data in addition to periodic backups. The difference between the two is infrastructure and the code that runs on it.
-  A warm standby maintains a minimum deployment that can handle requests, but at a reduced capacity—it cannot handle production-level traffic. 

## Multi-site active/active

<img width="762" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/17750286-da68-46cf-9257-b2819be5f474">

- With multi-site active/active, two or more Regions are actively accepting requests.
- Failover consists of re-routing requests away from a Region that cannot serve them.
- Here, data is replicated across Regions and is actively used to serve read requests in those Regions. For write requests, you can use several patterns that include writing to the local Region or re-routing writes to specific Regions. 

---
reference
- https://aws.amazon.com/ko/blogs/architecture/disaster-recovery-dr-architecture-on-aws-part-i-strategies-for-recovery-in-the-cloud/
- https://aws.amazon.com/ko/blogs/architecture/disaster-recovery-dr-architecture-on-aws-part-iii-pilot-light-and-warm-standby/