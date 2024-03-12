
- HashiCorp Vault is an identity-based secrets and encryption management system.

- A secret is anything that you want to tightly control access to, such as API encryption keys, passwords, and certificates. 

- Vault provides encryption services that are gated by authentication and authorization methods. Using Vault’s UI, CLI, or HTTP API, access to secrets and other sensitive data can be securely stored and managed, tightly controlled (restricted), and auditable.

<img width="600" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/c9fc5830-d5e2-466b-93d9-de3939beed9c">

## Barrier

<img width="574" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/293d325e-b350-4321-bd92-c6d6eb4d7aec">

```go
// SecurityBarrier is a critical component of Vault. It is used to wrap
// an untrusted physical backend and provide a single point of encryption,
// decryption and checksum verification. 

// The goal is to ensure that any
// data written to the barrier is confidential and that integrity is preserved.

// As a real-world analogy, this is the steel and concrete wrapper around
// a Vault. The barrier should only be Unlockable given its key.

type SecurityBarrier interface {
    ...

	// keyring is used to maintain all of the encryption keys, including
	// the active key used for encryption, but also prior keys to allow
	// decryption of keys encrypted under previous terms.
	Keyring() (*Keyring, error)

	// SecurityBarrier must provide the storage APIs
	logical.Storage

	// SecurityBarrier must provide the encryption APIs
	BarrierEncryptor
    ...
}
```

- Vault’s encryption layer, referred to as the **barrier**, is responsible for **encrypting and decrypting Vault data.**
  - When the Vault server starts, it writes data to its storage backend.
  - **Since the storage backend resides outside the barrier, it’s considered untrusted so Vault will encrypt the data before it sends them to the storage backend**.
  - This mechanism ensures that if a malicious attacker attempts to gain access to the storage backend, the data cannot be compromised since it remains encrypted, until Vault decrypts the data. The storage backend provides a durable data persistent layer where data is secured and available across server restarts.

---

## Seal/Unseal

- When a Vault server is started, it starts in a sealed state. In this state, Vault is configured to know where and how to access the physical storage, but doesn't know how to decrypt any of it.

- Unsealing is the process of **obtaining the plaintext root key necessary to read the decryption key to decrypt the data**, allowing access to the Vault.

- The data stored by Vault is encrypted. Vault needs the encryption key in order to decrypt the data. **The encryption key is also stored with the data** (in the keyring), but encrypted with another encryption key known as the root key.

- Therefore, to decrypt the data, Vault must **decrypt the encryption key which requires the root key**. Unsealing is the process of getting access to this root key. The root key is stored alongside all other Vault data, but is encrypted by yet another mechanism: the unseal key.

- To recap:
  - most Vault data is encrypted using the 'encryption key in the keyring';
  - the keyring is encrypted by the root key;
  - and the root key is encrypted by the unseal key.

<img width="641" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/d5b59519-c7da-4715-a94d-cb79bb608b07">


```go
// Keyring is used to manage multiple encryption keys used by
// the barrier. New keys can be installed and each has a sequential term.
// The term used to encrypt a key is prefixed to the key written out.

// All data is encrypted with the latest key, but storing the old keys
// allows for decryption of keys written previously. Along with the encryption
// keys, the keyring also tracks the root key. 

// This is necessary so that when a new key is added to the keyring, 
// we can encrypt with the root key and write out the new keyring.
type Keyring struct {
	rootKey        []byte
	keys           map[uint32]*Key
	activeTerm     uint32
	rotationConfig KeyRotationConfig
}
```

---
**reference**
- https://developer.hashicorp.com/vault/docs/concepts/seal#seal-unseal
- https://github.com/hashicorp/vault