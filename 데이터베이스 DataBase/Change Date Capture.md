# 💾 Change Date Capture

Traditionally, businesses used batch-based approaches to move data once or several times a day, However, vaych movement introduces latency and reduces the operational value to the organization.

But for now, Change Data Capture (CDC) has emerged as an ideal solutino for near real-time movement of data from relational databases to data warehouses, data lakes or other databases.

Change Data Capture is a software process **that identifies and tracks changes to data in a database**. **CDC provides real-time or near-real-time movement of data by moving and processing data continuously as new database events occur.**

<img width="605" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/28801703-eab4-4381-a1db-1d6372132c4a">

In high-velocity data environments where time-sensitive decisions are made, Change Data Capture is an excellent fit to achieve low-latency, relable, and scalable data replication. Change Data Capture is also ideal for zero downtime migrations to the cloud.

## Change Data Capture Methods

There are multiple common Change Data Capture methods that you can implement depending on your application requirements and tolerance for performance overhead. Here are the common methods, how they work, and their advantages as well as shortcomings.

### Audit Columns

By using existing `“LAST_UPDATED”` or `“DATE_MODIFIED”` columns, or by adding them if not available in the application, you can create your own change data capture solution at the application level. This approach retrieves only the rows that have been changed since the data was last extracted.

The CDC logic for the technique would be:

1. Get the maximum value of both the target (blue) table’s `Created_Time` and `Updated_Time` columns

2. Select all the rows from the data source with `Created_Time` greater than (>) the target table’s maximum `Created_Time`, which are all the newly created rows since the last CDC process was executed.

<img width="608" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/dbb11b80-0ca3-4755-b49a-84a7262c1318">

3. Select all rows from the source table that have an `Updated_Time` greater than (>) the target table’s maximum `Updated_Time` but less than (<) its maximum `Created_Time`.
    The reason for the exclusion of rows less than the maximum target create date is that they were included in step 2.

4. Insert new rows from step 2 or modify existing rows from step 3 in the target.

Pros of this method

- It can be built with native application logic
- It doesn’t require any external tooling
  
Cons of this method

- Adds additional overhead to the database
- DML statements such as deletes will not be propagated to the target without additional scripts to track deletes
- Error prone and likely to cause issues with data consistency
- This approach also requires CPU resources to scan the tables for the changed data and maintenance resources to ensure that the DATE_MODIFIED column is applied reliably across all source tables.

### Table Deltas

You can use table delta or ‘tablediff’ utilities to compare the data in two tables for non-convergence. Then you can use additional scripts to apply the deltas from the source table to the target as another approach to change data capture. There are [several examples of SQL scripts](https://www.mssqltips.com/sqlservertip/2779/ways-to-compare-and-find-differences-for-sql-server-tables-and-data/) that can find the difference of two tables.

<img width="587" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/848ee4fc-2f30-40de-8f32-d62baf0a66fd">

Advantages of this approach:

- It provides an accurate view of changed data while only using native SQL scripts

Disadvantage of this approach:

- Demand for storage significantly increases because you need three copies of the data sources that are being used in this technique: the original data, previous snapshot, and current snapshot
- It does not scale well in applications with heavy transactional workloads
  
Although this works better for managing deleted rows, the CPU resources required to identify the differences are significant and the overhead increases linearly with the volume of data. The diff method also introduces latency and cannot be performed in real time.

Some log-based change data capture tools come with the ability to [analyze different tables](https://www.striim.com/docs/en/creating-a-data-validation-dashboard.html) to ensure replication consistency.

### Trigger-based CDC

Another method for building change data capture at the application level is defining database triggers and creating your own change log in shadow tables. Triggers fire before or after INSERT, UPDATE, or DELETE commands (that indicate a change) and are used to create a change log. Operating at the SQL level, some users prefer this approach. Some databases even have [native support for triggers](https://docs.microsoft.com/en-us/sql/t-sql/statements/create-trigger-transact-sql?view=sql-server-ver15#:~:text=a%20trigger%20is%20a%20special,on%20a%20table%20or%20view.).

However, triggers are required for each table in the source database, and they have greater overhead associated with running triggers on operational tables while the changes are being made. In addition to having a significant impact on the performance of the application, maintaining the triggers as the application change leads to management burden.

Advantages of this approach:

- Shadow tables can provide an immutable, detailed log of all transactions
- Directly supported in the SQL API for some databases

Disadvantage of this approach:

- Significantly reduces the performance of the database by requiring multiple writes to a database every time a row is inserted, updated, or deleted
- Many application users do not want to risk the application behavior by introducing triggers to operational tables. DBAs and data engineers should always heavily test the performance of any triggers added into their environment and decide if they can tolerate the additional overhead.

### Log-Based Change Data Capture

Databases contain transaction logs (also called redo logs) that store all database events allowing for the database to be recovered in the event of a crash. With [log-based change data capture](https://www.striim.com/blog/log-based-change-data-capture/), new database transactions – including inserts, updates, and deletes – are read from source databases’ native transaction logs.

<img width="609" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/10f68e7e-a3ac-47b8-9716-3826d5bbcbdf">

The changes are captured without making application level changes and without having to scan operational tables, both of which add additional workload and reduce source systems’ performance.

Advantages of this approach

- **Minimal impact on production database system** – no additional queries required for each transaction
- Can maintain ACID reliability across multiple systems
- No requirement to change the production database system’s schemas or the need to add additional tables
  
Challenges of this approach

- Parsing the internal logging format of a database is complex – most databases do not document the format nor do they announce changes to it in new releases. This would potentially require you to change your database log parsing logic with each new database release.
- Would need system to manage the source database change events metadata
- Additional log levels required to produce scannable transaction logs can add marginal performance overhead

---
reference
- https://www.striim.com/blog/change-data-capture-cdc-what-it-is-and-how-it-works/