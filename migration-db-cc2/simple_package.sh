#!/bin/bash

echo "📦 Simple Chaincode Packaging for migration-db-cc2"
echo "=================================================="

# Configuration
CHAINCODE_NAME="migration-db-cc2"
CHAINCODE_VERSION="1.0"

cd /home/thien/linkid-chaincode/migration-db-cc2

echo "📋 Packaging Information:"
echo "• Name: $CHAINCODE_NAME"
echo "• Version: $CHAINCODE_VERSION"
echo "• Language: Go"
echo ""

# Clean up previous packages
echo "🧹 Cleaning previous packages..."
rm -f *.tar.gz

# Create package with tar
echo "📦 Creating package..."
tar -czf ${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz \
    main.go \
    go.mod \
    go.sum \
    README.md

if [ -f "${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz" ]; then
    echo "✅ Package created successfully!"
    echo "📦 Package: ${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz"
    echo "📏 Size: $(ls -lh ${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz | awk '{print $5}')"
    echo ""
    echo "📋 Package contents:"
    tar -tzf ${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz
    echo ""
    echo "🚀 Ready for deployment!"
    echo ""
    echo "Next steps:"
    echo "1. Copy package to Fabric network: scp ${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz user@fabric-peer:~/"
    echo "2. Install: peer lifecycle chaincode install ${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz"
    echo "3. Approve and commit to channel"
else
    echo "❌ Failed to create package!"
    exit 1
fi
