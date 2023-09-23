# S3 Glacier Vault Lock

- S3 Glacier Vault Lock helps you to easily deploy and enforce compliance controls for individual S3 Glacier vaults with a Valut Lock policy.

- You can specify controls such as "write once read many"  (WORM) in a Vault Lock policy and lock the policy from future edits.

> After a Vault Lock policy is locked, the policy can no longer be changed or deleted.

- S3 Glacier enforces the controls set in the Vault Lock policy to help achieve your compliance objectives. For example, you can use Vault Lock policies to enforce data retention. You can deploy a variety of compliance controls in a [Vault Lock policy](https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock-policy.html) by using the AWS IAM policy language.

- A Vault Lock policy is different from a vault access policy. Both policies govern access controls to your vault. However, a Vault Lock policy can be locked to prevent future changes, which provides strong enforcement for your compliance controls.

-  You can use the Vault Lock policy to deploy regulatory and compliance controls, whice typically require tight controls on data access. In contrast, you use a vault access policy to implement access controls that are not compliance related, temporary, and subject to frequent modification. 

- You can use Vault lock and vault access policies together. For example, you can implement time-based data-retention rules in the Vault Lock policy (deny deletes), and grant read access to designated third parties or your business partners (allow reads) in your vault access policy.

- Locking a vault takes two steps:
  1. Intiate the lock by attaching a Vault Lock poly to your vault, which sets the lock to an in-progress state and returns a lock ID. While the policy is in the in-progress state, you have 24 hours to validate you Vault Lock policy before the lock ID expires. To prevent your vault from exiting the in-progress state, you must complete the Vault Lock process within these 24 hours. Otherwise, your Vault Lock policy will be deleted.
  2. Use the lock ID to complete the lock process. If the Vault Lock policy doesn't work as expected, you can stop the Vault Lock process and restart from the beginning. 

## Policy Example

### Deny Deletion Permissions for Archives Less Than 365 Days Old

Suppose that you have a regulatory requirement to retain archives for up to one year before you can delete them. You can enforce that requirement by implementing the following Vault Lock policy. The policy denies the `glacier:DeleteArchive` action on the examplevault vault if the archive being deleted is less than one year old. The policy uses the S3 Glacier-specific condition key `ArchiveAgeInDays` to enforce the one-year retention requirement.

```json
{
    "Version":"2012-10-17",
    "Statement":[
        {
            "Sid": "deny-based-on-archive-age",
            "Principal": "*",
            "Effect": "Deny",
            "Action": "glacier:DeleteArchive",
            "Resource": [
                "arn:aws:glacier:us-west-2:123456789012:vaults/examplevault"
            ],
            "Condition": {
                "NumericLessThan" : {
                    "glacier:ArchiveAgeInDays" : "365"
                }
            }
        }
    ]
}   
```

### Deny Deletion Permissions Based on a Tag

Suppose that you have a time-based retention rule that an archive can be deleted if it is less than a year old. At the same time, suppose that you need to place a legal hold on your archives to prevent deletion or modification for an indefinite duration during a legal investigation. In this case, the legal hold takes precedence over the time-based retention rule specified in the Vault Lock policy.

To put these two rules in place, the following example policy has two statements:

- The first statement denies deletion permissions for everyone, locking the vault. This lock is performed by using the `LegalHold` tag.
- The second statement grants deletion permissions when the archive is less than 365 days old. But even when archives are less than 365 days old, no one can delete them when the condition in the first statement is met.

```json
{
    "Version":"2012-10-17",
    "Statement":[
        {
            "Sid": "lock-vault",
            "Principal": "*",
            "Effect": "Deny",
            "Action": [
                "glacier:DeleteArchive"
            ],
            "Resource": [
                "arn:aws:glacier:us-west-2:123456789012:vaults/examplevault"
            ],
            "Condition": {
                "StringLike": {
                    "glacier:ResourceTag/LegalHold": [
                        "true",
                        ""
                    ]
                }
            }
        },
        {
            "Sid": "you-can-delete-archive-less-than-1-year-old",
            "Principal": {
                "AWS": "arn:aws:iam::123456789012:root"
            },
            "Effect": "Allow",
            "Action": [
                "glacier:DeleteArchive"
            ],
            "Resource": [
                "arn:aws:glacier:us-west-2:123456789012:vaults/examplevault"
            ],
            "Condition": {
                "NumericLessThan": {
                    "glacier:ArchiveAgeInDays": "365"
                }
            }
        }
    ]
}            
```

---
reference
- https://docs.aws.amazon.com/amazonglacier/latest/dev/vault-lock-policy.html