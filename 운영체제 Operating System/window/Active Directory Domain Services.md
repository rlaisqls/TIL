# Active Directory Domain Services

- A directory is a **hierarchical structure** that stores information about objects on the network. 

- A directory service, such as Active Directory Domain Services (AD DS), provides the methods for storing directory data and making this data available to network users and administrators. 

- For example, AD DS stores information about user accounts, such as names, passwords, phone numbers, and so on, and enables other authorized users on the same network to access this information. 

- Active Directory stores information about objects on the network and makes this information easy for administrators and users to find and use. Active Directory uses a structured data store as the basis for a logical, hierarchical organization of directory information.

### Characteristics

- The AD DS is a true directory service that uses a hierarchical 'X.500' infrastructure.
- The AD DS uses Domain Name System (DNS) to locate resources, such as domain controllers.
- You can query and manage ADDS using Lightweight Directory Access Protocol (LDAP) calls.
- The AD DS primarily uses the Kerberos protocol for authentication.
- The AD DS uses OU and GPO for management.
- The AD DS includes computer objects that represent computers joining the Active Directory domain.
- The AD DS uses interdomain trusts for delegated management.

### A key element

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/cab61ca5-4d34-4c48-8e0a-91d3abe131de)

- **A set of rules, the schema**, that defines the classes of objects and attributes contained in the directory, the constraints and limits on instances of these objects, and the format of their names. For more information about the schema, see Schema.

- **A global catalog** that contains information about every object in the directory. This allows users and administrators to find directory information regardless of which domain in the directory actually contains the data. For more information about the global catalog, see Global catalog.

- **A query and index mechanism**, so that objects and their properties can be published and found by network users or applications. For more information about querying the directory, see Searching in Active Directory Domain Services.

- **A replication service** that distributes directory data across a network. All domain controllers in a domain participate in replication and contain a complete copy of all directory information for their domain. Any change to directory data is replicated to all domain controllers in the domain. For more information about Active Directory replication, see Active Directory Replication Concepts.

---
reference
- https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2003/cc736627(v=ws.10)
- https://learn.microsoft.com/ko-kr/training/modules/understand-azure-active-directory/3-compare-azure-active-directory-domain-services