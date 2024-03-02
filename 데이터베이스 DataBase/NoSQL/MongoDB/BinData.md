
BinData is binary data object that use in mongoDB. BinData consists of `subType` and `base64str`.

```bash
help misc
b = new BinData(subtype,base64str)  create a BSON BinData value
```

The BSON BinData datatype is represented via class BinData in the shell, each value represent specipic kind. like below :

```js
binary  ::=   int32 subtype (byte*)   Binary - The int32 is the number of bytes in the (byte*).
subtype ::=   "\x00"  Generic binary subtype
  |   "\x01"  Function
  |   "\x02"  Binary (Old)
  |   "\x03"  UUID (Old)
  |   "\x04"  UUID
  |   "\x05"  MD5
  |   "\x80"  User defined
```

### example

**Insert a `BinData()` Object**

Use the `BinData()` constructor to create the bdata variable.

```js
var bdata = BinData(0, "gf1UcxdHTJ2HQ/EGQrO7mQ==")
```

Insert the object into the testbin collection.

```js
db.testbin.insertOne( { _id : 1, bin_data: bdata } )
```

Query the testbin collection for the inserted document.

```js
db.testbin.find()
```

You can see the binary buffer stored in the collection.

```js
{
  _id: 1,
  bin_data: Binary(Buffer.from("81fd547317474c9d8743f10642b3bb99", "hex"), 0)
}
```

**Get the Length of BinData() Object**

Use the `BinData()` constructor to create the bdata variable.

```js
var bdata = BinData(0, "gf1UcxdHTJ2HQ/EGQrO7mQ==")
```

Use `.length()` to return the bit length of the object.

```js
bdata.length()
```

The returned value is:

```js
16
```

---
reference 
- http://bsonspec.org/#/specification
- http://docs.mongodb.org/manual/reference/mongodb-extended-json/#binary