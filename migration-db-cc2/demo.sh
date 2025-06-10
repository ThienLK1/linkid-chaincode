#!/bin/bash

echo "🚀 Migration Chaincode Demo"
echo "================================"

export GOROOT=/usr/local/go
export GOPATH=/home/thien/go

cd /home/thien/linkid-chaincode/migration-db-cc2

echo "📋 Project Summary:"
echo "• Chaincode: SimpleBatchChaincode"
echo "• Purpose: Migrate CouchDB exported data to Hyperledger Fabric"
echo "• Functions: batchInsert, healthCheck"
echo ""

echo "🔧 Building chaincode..."
go build -o migration-db-cc2
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📦 Binary size: $(ls -lh migration-db-cc2 | awk '{print $5}')"
else
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "🧪 Running tests..."
go test -v
if [ $? -eq 0 ]; then
    echo "✅ All tests passed!"
else
    echo "❌ Tests failed"
fi

echo ""
echo "📊 Test Coverage:"
go test -cover

echo ""
echo "📁 Project Files:"
echo "• main.go - Main chaincode implementation"
echo "• comprehensive_test.go - Comprehensive test suite" 
echo "• simple_test.go - Basic functionality tests"
echo "• build.sh - Build script"
echo "• deploy_couchdb.sh - CouchDB deployment script"

echo ""
echo "🎯 Usage Example:"
echo "1. Package chaincode: tar -czf migration-db-cc2.tar.gz ."
echo "2. Install on Fabric network"
echo "3. Invoke with JSON data:"
echo '   {"function":"batchInsert","Args":["{\"documents\":[{\"_id\":\"test1\",\"name\":\"Test Doc\"}]}"]}'

echo ""
echo "🌐 CouchDB UI (if running): http://localhost:5984/_utils"
echo ""
echo "🎉 Demo completed successfully!"
