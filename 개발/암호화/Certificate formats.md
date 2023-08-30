# Certificate formats

SSL has been around for long enough you'd think that there would be agreed upon container formats. Many formats are using for implement it. But in the end, all of these are different ways to encode Abstract Syntax Notation 1 (ASN.1) formatted data — which happens to be the format x509 certificates are defined in — in machine-readable ways.

### `.csr`

> This is a Certificate Signing Request.

Some applications can generate these for submission to certificate-authorities. The actual format is PKCS10 which is defined in RFC 2986. It includes some/all of the key details of the requested certificate such as subject, organization, state, whatnot, as well as the public key of the certificate to get signed. These get signed by the CA and a certificate is returned. The returned certificate is the public certificate (which includes the public key but not the private key), which itself can be in a couple of formats.

### `.pem`

> PEM on it's own isn't a certificate, it's just a way of encoding data. X.509 certificates are one type of data that is commonly encoded using PEM.

PEM is a X.509 certificate (whose structure is defined using ASN.1), encoded using the ASN.1 DER (distinguished encoding rules), then run through Base64 encoding and stuck between plain-text anchor lines (BEGIN CERTIFICATE and END CERTIFICATE).

Defined in RFC 1422 (part of a series from 1421 through 1424) this is a container format that may include just the public certificate (such as with Apache installs, and CA certificate files /etc/ssl/certs), or may include an entire certificate chain including public key, private key, and root certificates.

Confusingly, it may also encode a CSR as the PKCS10 format can be translated into PEM. The name is from Privacy Enhanced Mail (PEM), a failed method for secure email but the container format it used lives on, and is a base64 translation of the x509 ASN.1 keys.

### `.key`

This is a (usually) PEM formatted file containing just the private-key of a specific certificate and is merely a conventional name and not a standardized one. In Apache installs, this frequently resides in /etc/ssl/private. The rights on these files are very important, and some programs will refuse to load these certificates if they are set wrong.

### `.pkcs12` `.pfx``.p12`

Originally defined by RSA in the Public-Key Cryptography Standards (abbreviated PKCS), the "12" variant was originally enhanced by Microsoft, and later submitted as RFC 7292. This is a password-protected container format that contains both public and private certificate pairs.

Unlike `.pem` files, this container is fully encrypted. Openssl can turn this into a `.pem` file with both public and private keys: `openssl pkcs12 -in file-to-convert.p12 -out converted-file.pem -nodes`

A few other formats that show up from time to time:

### `.der`
A way to encode ASN.1 syntax in binary, a .pem file is just a Base64 encoded .der file. OpenSSL can convert these to .pem (openssl x509 -inform der -in to-convert.der -out converted.pem). Windows sees these as Certificate files. By default, Windows will export certificates as .DER formatted files with a different extension. Like...

### `.cert .cer .crt`

A `.pem` (or rarely `.der`) formatted file with a different extension, one that is recognized by Windows Explorer as a certificate, which .pem is not.

### .p7b .keystore

Defined in RFC 2315 as PKCS number 7, this is a format used by Windows for certificate interchange. Java understands these natively, and often uses .keystore as an extension instead. Unlike `.pem` style certificates, this format has a defined way to include certification-path certificates.

### `.crl`

A certificate revocation list. Certificate Authorities produce these as a way to de-authorize certificates before expiration. You can sometimes download them from CA websites.

---

In summary, there are four different ways to present certificates and their components:

- **PEM** - Governed by RFCs, used preferentially by open-source software because it is text-based and therefore less prone to translation/transmission errors. It can have a variety of extensions (`.pem`, `.key`, `.cer`, `.cert`, more)
- **PKCS7** - An open standard used by Java and supported by Windows. Does not contain private key material.
- **PKCS12** - A Microsoft private standard that was later defined in an RFC that provides enhanced security versus the plain-text PEM format. This can contain private key and certificate chain material. Its used preferentially by Windows systems, and can be freely converted to PEM format through use of openssl.
- **DER** - The parent format of PEM. It's useful to think of it as a binary version of the base64-encoded PEM file. Not routinely used very much outside of Windows.

---
reference
- https://stackoverflow.com/questions/991758/openssl-pem-key
- https://gist.github.com/kirilkirkov/4c73da883088b6ff7420c49af1561b2b