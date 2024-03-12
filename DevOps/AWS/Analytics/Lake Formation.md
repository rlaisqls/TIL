
[AWS Lake Formation](https://aws.amazon.com/lake-formation/) is fully managed service that helps you build, secure, and manage data lakes, and provide access control for data in the data lake.

<img width="733" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/471181ea-62f5-4612-be25-57f0f1413eaf">

## Granular access permissions

Customers acress lines of business (LOBs) need a way to manage granular access permissions for different users at the table and column level. Lake Formation helps you manage fine-grained access for internal and external customers from a ventralized location and in a scalable way.

you can manage granular permissions on datasets shared between AWS accounts using Lake Formation.

Our use case assumes you’re using AWS Organizations to manage your AWS accounts. The user of Account A in one organizational unit (OU1) grants access to users of Account B in OU2. You can use this same approach when not using Organizations, such as when you only have a few accounts.

The following diagram illustrates the fine-grained access control of datasets in the data lake. 

- The data lake is available in the Account A.
- The data lake administrator of Account A provides fine-grained access for Account B.
  
The diagram also shows that a user of Account B provides column-level access of the Account A data lake table to another user in Account B.

<img width="495" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/33b6270b-4abb-467a-ba59-85c298ed217f">

---
reference
- https://aws.amazon.com/ko/blogs/big-data/manage-fine-grained-access-control-using-aws-lake-formation/
- https://aws.amazon.com/ko/lake-formation/
- https://docs.aws.amazon.com/lake-formation/latest/dg/what-is-lake-formation.html