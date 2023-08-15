# Context deadline exceeded

When a `context is canceled` or `its deadline is exceeded`, all operations associated with that **context are terminated, and the corresponding functions return with an error**. The error message "context deadline exceeded" indicates that the operation took longer than the deadline specified in the context.

In the example below, a context with a deadline of 2 seconds is created using context.WithTimeout. However, the performOperation function intentionally simulates a long-running operation that takes 3 seconds to complete. As a result, when the operation is executed with the context, the context deadline exceeded error is returned.

```go
package main

import (
	"context"
	"fmt"
	"time"
)

func main() {
	// Create a context with a deadline of 2 seconds.
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	// Simulate a long-running operation that takes more than 2 seconds.
	time.Sleep(3 * time.Second)

	// Perform some operation with the context.
	if err := performOperation(ctx); err != nil {
		fmt.Println("Error:", err)
	}
}

func performOperation(ctx context.Context) error {
	select {
	case <-ctx.Done():
		// The context deadline has been exceeded.
		return ctx.Err()
	default:
		// Perform the operation
		fmt.Println("Operation completed successfully")
		return nil
	}
}
```

## Solutions:

Before being able to solve the problem, you need to determine what is actually failing.

- **Investigate Network connectivity**
  - Can required systems communicate in general? Are there any firewalls in place that can be preventing communication? If in the cloud, are the instances in the same VPC/Network? Do the instances belong to the correct/expected Security Groups?
- **Resource Contention**
  - Are we asking too much of the underlying provisioned infrastructure? What is our CPU/Memory usage? 
- **Slow I/O**
  - Are we using an external storage backend? Are we seeing I/O wait? Are we in the cloud? Do we have enough IOPS provisioned for our storage?