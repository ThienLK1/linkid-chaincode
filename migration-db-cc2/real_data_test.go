package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"testing"
	"time"
	
	"github.com/hyperledger/fabric/core/chaincode/shim"
)

// This test demonstrates how the chaincode would work with real CouchDB exported data
func TestCouchDBIntegration(t *testing.T) {
	// Real CouchDB export data (based on your actual sample)
	exportedData := map[string]interface{}{
		"documents": []map[string]interface{}{
			{
				"_id":              "\u0000GlobalSetting\u0000DefaultPointUsagePriority10996167' or '5917'='5917\u0000",
				"_rev":             "1-61f029df0db1fe7f8256e1f5480d382c",
				"CreatedTime":      "2024-09-13T09:20:31Z",
				"Description":      "Default point usage priority",
				"GlobalSettingID":  "b8d3360575dcbd79614bf6db92ed1e233f7523",
				"Key":              "DefaultPointUsagePriority10996167' or '5917'='5917",
				"Status":           "A",
				"Unit":             "Merchant IDs",
				"UpdatedTime":      "2024-09-13T09:20:31Z",
				"Value":            "0",
				"~version":         "\u0000CgUDHaTGAA==",
			},
			{
				"_id":              "\u0000GlobalSetting\u0000MaxPointsPerTransaction\u0000",
				"_rev":             "1-abc123def456",
				"CreatedTime":      "2024-09-14T10:15:00Z",
				"Description":      "Maximum points allowed per transaction",
				"GlobalSettingID":  "c9e4471686edc8a725c8f7ec93fe2f344g8634",
				"Key":              "MaxPointsPerTransaction",
				"Status":           "A",
				"Unit":             "Points",
				"UpdatedTime":      "2024-09-14T10:15:00Z",
				"Value":            "10000",
				"~version":         "\u0000CgUDHbTGBB==",
			},
			{
				"_id":              "\u0000Member\u0000user123\u0000",
				"_rev":             "2-def789ghi012",
				"CreatedTime":      "2024-09-15T14:30:00Z", 
				"MemberID":         "user123",
				"Email":            "user@example.com",
				"Status":           "A",
				"PointBalance":     "5000",
				"UpdatedTime":      "2024-09-15T14:30:00Z",
				"~version":         "\u0000CgUDHcTGCC==",
			},
		},
	}

	// Convert to JSON (this is what your dApp would send to the chaincode)
	jsonData, err := json.Marshal(exportedData)
	if err != nil {
		t.Fatalf("Failed to marshal test data: %v", err)
	}

	fmt.Printf("📦 Sample CouchDB Export Data:\n%s\n\n", string(jsonData))

	// Test the chaincode with this data
	testChaincode(t, string(jsonData))

	// Optionally, you could also store this data in the real CouchDB for comparison
	storeInRealCouchDB(t, exportedData["documents"].([]map[string]interface{}))
	
	fmt.Println("🎉 Integration test completed successfully!")
}

func testChaincode(t *testing.T, jsonData string) {
	fmt.Println("🔧 Testing chaincode with mock stub...")
	
	cc := new(SimpleBatchChaincode)
	stub := shim.NewMockStub("test", cc)
	
	// Start mock transaction
	stub.MockTransactionStart("txid")
	defer stub.MockTransactionEnd("txid")
	
	// Test the batchInsert function
	response := cc.batchInsert(stub, []string{jsonData})
	
	if response.Status != 200 {
		t.Errorf("BatchInsert failed: %s", response.Message)
		return
	}
	
	var result BatchResult
	if err := json.Unmarshal(response.Payload, &result); err != nil {
		t.Errorf("Failed to parse result: %v", err)
		return
	}
	
	fmt.Printf("✅ Chaincode Results:\n")
	fmt.Printf("   Total Documents: %d\n", result.TotalDocs)
	fmt.Printf("   Successful: %d\n", result.SuccessfulDocs)
	fmt.Printf("   Failed: %d\n", result.FailedDocs)
	fmt.Printf("   Processing Time: %s\n", result.ProcessingTime)
	
	if len(result.Errors) > 0 {
		fmt.Printf("   Errors: %v\n", result.Errors)
	}
	
	// Verify data was stored correctly
	fmt.Println("\n🔍 Verifying stored data...")
	expectedKeys := []string{
		"\u0000GlobalSetting\u0000DefaultPointUsagePriority10996167' or '5917'='5917\u0000",
		"\u0000GlobalSetting\u0000MaxPointsPerTransaction\u0000",
		"\u0000Member\u0000user123\u0000",
	}
	
	for _, key := range expectedKeys {
		data, err := stub.GetState(key)
		if err != nil {
			t.Errorf("Failed to get state for %s: %v", key, err)
			continue
		}
		if data == nil {
			t.Errorf("Data not found for key: %s", key)
			continue
		}
		
		var doc map[string]interface{}
		if err := json.Unmarshal(data, &doc); err != nil {
			t.Errorf("Failed to unmarshal stored data for %s: %v", key, err)
			continue
		}
		
		// Show different fields based on document type
		if description, exists := doc["Description"]; exists {
			fmt.Printf("   ✓ GlobalSetting: %s\n", description)
		} else if memberID, exists := doc["MemberID"]; exists {
			fmt.Printf("   ✓ Member: %s\n", memberID)
		} else {
			fmt.Printf("   ✓ Document stored: %s\n", key[:50]+"...")
		}
	}
}

func storeInRealCouchDB(t *testing.T, documents []map[string]interface{}) {
	fmt.Println("\n💾 Storing sample data in real CouchDB for comparison...")
	
	// Create database
	createDB := func(dbName string) {
		url := fmt.Sprintf("http://admin:password@localhost:5984/%s", dbName)
		req, _ := http.NewRequest("PUT", url, nil)
		client := &http.Client{Timeout: 10 * time.Second}
		resp, err := client.Do(req)
		if err == nil {
			resp.Body.Close()
		}
	}
	
	createDB("migration_test")
	
	// Store each document
	for _, doc := range documents {
		docJSON, _ := json.Marshal(doc)
		url := fmt.Sprintf("http://admin:password@localhost:5984/migration_test/%s", doc["_id"])
		
		req, _ := http.NewRequest("PUT", url, bytes.NewBuffer(docJSON))
		req.Header.Set("Content-Type", "application/json")
		
		client := &http.Client{Timeout: 10 * time.Second}
		resp, err := client.Do(req)
		if err != nil {
			fmt.Printf("   ⚠️  Failed to store %s: %v\n", doc["_id"], err)
			continue
		}
		
		body, _ := io.ReadAll(resp.Body)
		resp.Body.Close()
		
		if resp.StatusCode == 201 || resp.StatusCode == 200 {
			fmt.Printf("   ✓ Stored %s in CouchDB\n", doc["_id"])
		} else {
			fmt.Printf("   ⚠️  Failed to store %s: %s\n", doc["_id"], string(body))
		}
	}
	
	fmt.Println("\n🌐 You can view the data at: http://localhost:5984/_utils/#/database/migration_test/_all_docs")
}
