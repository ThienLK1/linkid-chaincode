#!/bin/bash

echo "📦 Hyperledger Fabric Chaincode Packaging Script"
echo "================================================="

# Set environment variables
export GOROOT=/usr/local/go
export GOPATH=/home/thien/go

# Configuration
CHAINCODE_NAME="migration-db-cc2"
CHAINCODE_VERSION="1.0"
CHAINCODE_SEQUENCE="1"
CHANNEL_NAME="mychannel"

cd /home/thien/linkid-chaincode/migration-db-cc2

echo "📋 Chaincode Information:"
echo "• Name: $CHAINCODE_NAME"
echo "• Version: $CHAINCODE_VERSION"
echo "• Language: Go"
echo "• Type: Migration utility for CouchDB data"
echo ""

# Step 1: Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -f *.tar.gz
rm -f migration-db-cc2
go clean
echo "✅ Clean completed"
echo ""

# Step 2: Run tests (excluding integration tests that need CouchDB)
echo "🧪 Running core tests..."
go test -run TestComprehensive -v
if [ $? -eq 0 ]; then
    echo "✅ Core tests passed!"
else
    echo "⚠️  Some tests failed, but continuing with packaging..."
fi
echo ""

# Step 3: Build the chaincode
echo "🔨 Building chaincode..."
go build -o $CHAINCODE_NAME
if [ $? -ne 0 ]; then
    echo "❌ Build failed! Cannot package."
    exit 1
fi
echo "✅ Build successful!"
echo "📏 Binary size: $(ls -lh $CHAINCODE_NAME | awk '{print $5}')"
echo ""

# Step 4: Create chaincode package
echo "📦 Creating chaincode package..."

# Create temporary directory for packaging
TEMP_DIR="/tmp/chaincode-package-$$"
mkdir -p $TEMP_DIR

# Copy necessary files to temp directory
echo "📋 Including files:"
cp main.go $TEMP_DIR/ && echo "  ✓ main.go"
cp go.mod $TEMP_DIR/ && echo "  ✓ go.mod" 
cp go.sum $TEMP_DIR/ && echo "  ✓ go.sum"

# Optional: Include README and documentation
if [ -f "README.md" ]; then
    cp README.md $TEMP_DIR/ && echo "  ✓ README.md"
fi

if [ -f "DEPLOYMENT_GUIDE.md" ]; then
    cp DEPLOYMENT_GUIDE.md $TEMP_DIR/ && echo "  ✓ DEPLOYMENT_GUIDE.md"
fi

echo ""

# Create the package using peer lifecycle (if peer CLI is available)
if command -v peer &> /dev/null; then
    echo "🔧 Using peer CLI to create package..."
    peer lifecycle chaincode package ${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz \
        --path $TEMP_DIR \
        --lang golang \
        --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION}
    
    if [ $? -eq 0 ]; then
        echo "✅ Chaincode package created: ${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz"
        PACKAGE_FILE="${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz"
    else
        echo "⚠️  peer CLI packaging failed, using tar..."
        cd $TEMP_DIR
        tar -czf ../${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz .
        cd - > /dev/null
        mv ${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz ./
        PACKAGE_FILE="${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz"
    fi
else
    echo "🔧 peer CLI not found, using tar for packaging..."
    cd $TEMP_DIR
    tar -czf ../${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz .
    cd - > /dev/null
    mv ${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz ./
    PACKAGE_FILE="${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz"
fi

# Clean up temp directory
rm -rf $TEMP_DIR

# Verify package
if [ -f "$PACKAGE_FILE" ]; then
    echo ""
    echo "✅ Package created successfully!"
    echo "📦 Package: $PACKAGE_FILE"
    echo "📏 Package size: $(ls -lh $PACKAGE_FILE | awk '{print $5}')"
    echo ""
    
    # Show package contents
    echo "📋 Package contents:"
    tar -tzf $PACKAGE_FILE | sed 's/^/  /'
    echo ""
    
    # Generate deployment commands
    echo "🚀 Deployment Commands:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1️⃣  Install chaincode on peers:"
    echo "   peer lifecycle chaincode install $PACKAGE_FILE"
    echo ""
    echo "2️⃣  Query installed chaincodes (get package ID):"
    echo "   peer lifecycle chaincode queryinstalled"
    echo ""
    echo "3️⃣  Approve chaincode definition (replace PACKAGE_ID):"
    echo "   peer lifecycle chaincode approveformyorg \\"
    echo "     --channelID $CHANNEL_NAME \\"
    echo "     --name $CHAINCODE_NAME \\"
    echo "     --version $CHAINCODE_VERSION \\"
    echo "     --package-id PACKAGE_ID \\"
    echo "     --sequence $CHAINCODE_SEQUENCE \\"
    echo "     --tls \\"
    echo "     --cafile \$ORDERER_CA"
    echo ""
    echo "4️⃣  Commit chaincode definition:"
    echo "   peer lifecycle chaincode commit \\"
    echo "     --channelID $CHANNEL_NAME \\"
    echo "     --name $CHAINCODE_NAME \\"
    echo "     --version $CHAINCODE_VERSION \\"
    echo "     --sequence $CHAINCODE_SEQUENCE \\"
    echo "     --tls \\"
    echo "     --cafile \$ORDERER_CA \\"
    echo "     --peerAddresses \$CORE_PEER_ADDRESS \\"
    echo "     --tlsRootCertFiles \$CORE_PEER_TLS_ROOTCERT_FILE"
    echo ""
    echo "5️⃣  Test chaincode:"
    echo "   # Health check"
    echo "   peer chaincode invoke \\"
    echo "     -C $CHANNEL_NAME \\"
    echo "     -n $CHAINCODE_NAME \\"
    echo "     -c '{\"function\":\"healthCheck\",\"Args\":[]}'"
    echo ""
    echo "   # Batch insert (replace with your data)"
    echo "   peer chaincode invoke \\"
    echo "     -C $CHANNEL_NAME \\"
    echo "     -n $CHAINCODE_NAME \\"
    echo "     -c '{\"function\":\"batchInsert\",\"Args\":[\"{\\\"documents\\\":[{\\\"_id\\\":\\\"test1\\\",\\\"name\\\":\\\"Test\\\"}]}\"]}"
    echo ""
    echo "📝 Package ready for deployment to Hyperledger Fabric network!"
    echo "🎯 Your chaincode handles CouchDB export data migration efficiently."
    
else
    echo "❌ Failed to create package!"
    exit 1
fi
