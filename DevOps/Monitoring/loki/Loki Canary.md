
- Loki Canary is a standalone app that audits the log-capturing performance of a Grafana Loki cluster.

- Loki Canary generates artificial log lines. These log lines are sent to the Loki cluster.
  
- Loki Canary communicates with the Loki cluster to capture metrics about the artificial log lines, such that Loki Canary forms inforation about the performance of the Loki cluster. The information is available as Prometheus time series metrics.

<img width="500" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/c3e7da3d-77d0-4e0c-b732-573660527409">

- Loki Canary writes a log to a file and stores the timestamp in an internal array. The contents look something like this.
    ```
    1557935669096040040 ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp
    ```

- The relevant part of the log entry is the timestamp; the `p`s are just filler bytes to make the size of the log configurable.

- An agent (like Promtail) should be configured to read the log file and ship it to Loki.

- Meanwhile, Loki Canary will open a WebSocket connection to Loki and will tail the logs it creates. When a log is received on the WebSocker, the timestamp in the log message is compared to the internal array.

- If the received log is:
  - The next in the array to be received, it is removed from the array and the (current time - log timestamp) is recorded in the `response_latency` histogram. This is the expected behavior for well behaving logs.
  - Not the next in the array to be received, it is removed from the array, the response time is recorded in the `response_latency` histogram, and the `out_of_order_entries` counter is incremented.
  - Not in the array at all, it is checked against a separate list of received logs to either increment the `duplicate_entries` counter or the `unexpected_entries` counter.

- In the background, Loki Canry also runs a timer which iterates through all of the entries in the internal array.
  - If any of the entries are older than the duration specified by the `-wait` flag (defaulting to 50s), they are removed from the array and the `websocket_missing_entries` counter is incremented.
  - An additional query is then made directly to Loki for any missing entries to determine if they are truly missing or only missing from the WebSocket. If missing entries are not found in the direcy query, the `missing_entries` counter is incremented.

---

## Additional Queries

### Spot Check

- The canary will spot check certain result over time to make sure they are present in Loki, this is helpful for testing the transition of inmemory logs in the ingesyer to the store to make sure nothing is lost.

- `-spot-check-interval`(default `15m`) and `-spot-check-max`(default `4h`) are used to tune this feature, `-spot-check-interval` will pull a log entry from the stream at this interval and save it in a separate list up to `-spot-check-max`.

- Every `-spot-check-query-rate`, Loki will be queried for each entry in this list and `loki_canary_spot check entries_total` will be incremented.

> NOTE: if you are using `out-of-order-percentage` to test ingestion of out-of-order log lines be sure not to set the two out of order time range flags too far in the past. The defaults are already enough to test this functionality properly, and setting them too far in the past can cause issues with the spot check test.
> When using `out-of-order-percentage` you also need to make use of pipeline stages in your Promtail configuration in order to set the timestamps correctly as the logs are pushed to Loki. The client/promtail/pipelines docs have examples of how to do this.

### Metric Test

- Loki Canary will run a metric query `count_over_time` to verify that the rate of logs being stored in Loki corresponds to the rate they are being created by Loki Canary.

- `-metric-test-interval` and `-metric-test-range` are used to tume this feature, but by default every `15m` the canary will run a `count_over_time` instant-query to Loki for a range fo `24h`.

- If the canary has not run for `-metric-test-range` (`24h`) the query range is adjusted to the amount of time the canary has been running such that the rate can be calculated since the canary wes started.

- The canary calculates what the expected count of logs would be for the range (also adjusting this based on canary runtime) and compares the expected result with the actual result returned from Loki. The difference is stored as the value in the guage `loki_canary_metric_test_deviation` 

---
reference
- https://grafana.com/docs/loki/latest/operations/loki-canary/

