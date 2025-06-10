# SimpleBatchChaincode (migration-db-cc2)

Ultra-simple chaincode for Hyperledger Fabric that handles:
- Batch data insertion from dApps to CouchDB
- Data migration from old chaincodes
- Schema-free operations (no models or validation)

## Features

1. **Schema-Free**: No predefined models, accepts any JSON structure
2. **Batch Operations**: Efficiently processes multiple documents at once
3. **Migration Support**: Can migrate data from old chaincodes
4. **Minimal Dependencies**: Only requires Hyperledger Fabric

## Functions

### 1. batchInsert
Inserts batch data from dApp to CouchDB.

**Input:**
```json
{
  "collection": "Members",
  "documents": [
    {
      "id": "member1",
      "name": "John Doe",
      "balance": 100.0
    },
    {
      "id": "member2", 
      "name": "Jane Smith",
      "balance": 250.0
    }
  ]
}
```

**Output:**
```json
{
  "collection": "Members",
  "totalDocs": 2,
  "successfulDocs": 2,
  "failedDocs": 0,
  "processingTime": "15.2ms"
}
```

### 2. migrateFromOldCC
Migrates data from old chaincode by collection type.

**Input:**
```bash
peer chaincode invoke -C mychannel -n migration-db-cc2 -c '{"function":"migrateFromOldCC","Args":["Member"]}'
```

### 3. healthCheck
Returns chaincode health status.

**Output:**
```json
{
  "status": "OK",
  "chaincode": "SimpleBatchChaincode",
  "timestamp": "2025-06-10T10:30:00Z",
  "txId": "abc123..."
}
```

## Usage Examples

### From dApp (Node.js)
```javascript
const data = {
  collection: "TokenTrans",
  documents: [
    {
      id: "tx001",
      fromWallet: "wallet1",
      toWallet: "wallet2", 
      amount: 50.0,
      actionType: "transfer"
    },
    {
      id: "tx002",
      fromWallet: "wallet2",
      toWallet: "wallet3",
      amount: 25.0,
      actionType: "transfer"  
    }
  ]
};

await contract.submitTransaction('batchInsert', JSON.stringify(data));
```

### CLI Commands
```bash
# Batch insert
peer chaincode invoke -C mychannel -n migration-db-cc2 \
  -c '{"function":"batchInsert","Args":["{\"collection\":\"Members\",\"documents\":[{\"id\":\"m1\",\"name\":\"John\"}]}"]}'

# Migrate data
peer chaincode invoke -C mychannel -n migration-db-cc2 \
  -c '{"function":"migrateFromOldCC","Args":["TokenTrans"]}'

# Health check
peer chaincode invoke -C mychannel -n migration-db-cc2 \
  -c '{"function":"healthCheck","Args":[]}'
```

## Document Structure

All documents automatically get these metadata fields:
- `_collection`: Collection name
- `_createdAt`: Creation timestamp (RFC3339)
- `_txId`: Transaction ID
- `_migratedAt`: Migration timestamp (for migrated docs)
- `_migratedFrom`: Original key (for migrated docs)

## Build & Deploy

```bash
# Build
go mod tidy
go build

# Package for deployment
tar -czf migration-db-cc2.tar.gz .

# Install & deploy using peer CLI or Fabric SDK
```

## Benefits

1. **No Schema Constraints**: Accept any JSON structure from dApps
2. **High Performance**: Batch processing reduces transaction overhead
3. **Simple Integration**: Minimal code, easy to understand and maintain
4. **CouchDB Optimized**: Direct PutState operations for efficient storage
5. **Migration Ready**: Built-in support for data migration scenarios
