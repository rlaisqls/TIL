
![image](https://github.com/rlaisqls/TIL/assets/81006587/99a9ce84-a556-40c6-9e90-c8f29f216a26)

- openHistorian is a back-office system developed by the GridProtectionAlliance that is designed to efficiently integrate and archive process control data, such as SCADA, synchrophasor, digital fault recorder, or any other time-series data used to support process operations. 

- It is optimized to store and retrieve large volumes of time-series data quickly and efficiently, including high-resolution sub-second information.

![image](https://github.com/rlaisqls/TIL/assets/81006587/4c88de55-bd56-42fe-a210-dd68bb17d337)

### Overview

The openHistorian 2 is built using the GSF SNAPdb Engine - a key/value pair archiving technology developed to significantly improve the ability to archive extremely large volumes of real-time streaming data and directly serve the data to consuming applications and systems.

Through use of the SNAPdb Engine, the openHistorian inherits very fast performance with very low lag-time for data insertion. The openHistorian 2 is a time-series implementation of the SNABdb engine where the "key" is a tuple of time and measurement ID, and the "value" is the stored data - which can be most any data type and associated flags.

The system comes with a high-speed API that interacts with an in-memory cache for very high speed extraction of near real-time data. The archive files produced by the openHistorian are ACID Compliant which create a very durable and consistent file structure that is resistant to data corruption. Internally the data structure is based on a B+ Tree that allows out-of-order data insertion.

The openHistorian service also hosts the GSF Time-Series Library (TSL), creating an ideal platform for integrating streaming time-series data processing in real-time:

![image](https://github.com/rlaisqls/TIL/assets/81006587/665d4e2d-2b04-44b7-9376-ac58d56cf88b)

### Integrate with Grafana 

By using the openHistorian plugin for Grafana, users can connect Grafana to their openHistorian instance and leverage its capabilities to query and visualize historical data within Grafana's intuitive and customizable dashboards.

Building a metric query using the openHistorian Grafana data source begins with the selection of a query type, one of: Element List, Filter Expression or Text Editor. The Element List and Filter Expression types are query builder screens that assist with the selection of the desired series. The Text Editor screen allows for manual entry of a query expression that will select the desired series.

![image](https://github.com/rlaisqls/TIL/assets/81006587/3b916bc4-cee5-49f3-94d7-f68071bf240c)

---
reference
- https://github.com/GridProtectionAlliance/openHistorian
- https://grafana.com/grafana/plugins/gridprotectionalliance-openhistorian-datasource/