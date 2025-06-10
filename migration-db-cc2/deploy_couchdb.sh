#!/bin/bash

# CouchDB Test Deployment Script

echo "🚀 Starting CouchDB for testing..."

# Start CouchDB
docker-compose up -d

echo "⏳ Waiting for CouchDB to be ready..."
sleep 10

# Wait for CouchDB health check
echo "🔍 Checking CouchDB health..."
while ! curl -s http://localhost:5984/_up | grep -q '"status":"ok"'; do
    echo "Waiting for CouchDB to be healthy..."
    sleep 5
done

echo "✅ CouchDB is ready!"

# Create a test database
echo "📝 Creating test database..."
curl -X PUT http://admin:password@localhost:5984/testdb

# Test CouchDB connection
echo "🧪 Testing CouchDB connection..."
curl -s http://admin:password@localhost:5984/ | jq .

echo ""
echo "🎉 CouchDB deployment complete!"
echo ""
echo "CouchDB Admin UI: http://localhost:5984/_utils"
echo "Username: admin"
echo "Password: password"
echo ""
echo "To test the chaincode with real CouchDB:"
echo "1. Run: go run integration_test.go"
echo "2. Or run: bash test_with_couchdb.sh"
echo ""
echo "To stop CouchDB:"
echo "docker-compose down"
