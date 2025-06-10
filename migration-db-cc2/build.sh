#!/bin/bash

echo "Building SimpleBatchChaincode (migration-db-cc2)..."

# Clean up
go clean

# Download dependencies
go mod tidy

# Run tests
echo "Running tests..."
go test -v

# Build
echo "Building chaincode..."
go build -o migration-db-cc2

echo "Build completed successfully!"
echo ""
echo "To deploy this chaincode:"
echo "1. Package: tar -czf migration-db-cc2.tar.gz ."
echo "2. Install using peer CLI or Fabric SDK"
echo ""
echo "Example invoke commands:"
echo "# Health check:"
echo "peer chaincode invoke -C mychannel -n migration-db-cc2 -c '{\"function\":\"healthCheck\",\"Args\":[]}'"
echo ""
echo "# Batch insert:"
echo "peer chaincode invoke -C mychannel -n migration-db-cc2 -c '{\"function\":\"batchInsert\",\"Args\":[\"{\\\"collection\\\":\\\"Members\\\",\\\"documents\\\":[{\\\"id\\\":\\\"m1\\\",\\\"name\\\":\\\"John\\\"}]}\"]}'"
