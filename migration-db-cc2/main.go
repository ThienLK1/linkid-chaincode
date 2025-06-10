package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

// SimpleBatchChaincode - Ultra simple chaincode for batch operations
type SimpleBatchChaincode struct{}

// BatchData represents the data structure from dApp for migration
type BatchData struct {
	Documents []map[string]interface{} `json:"documents"`
}

// BatchResult shows the result of batch operation
type BatchResult struct {
	TotalDocs      int      `json:"totalDocs"`
	SuccessfulDocs int      `json:"successfulDocs"`
	FailedDocs     int      `json:"failedDocs"`
	ProcessingTime string   `json:"processingTime"`
	Errors         []string `json:"errors,omitempty"`
}

// Init - Initialize chaincode
func (cc *SimpleBatchChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success([]byte("SimpleBatchChaincode initialized"))
}

// Invoke - Handle chaincode invocations
func (cc *SimpleBatchChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()

	switch function {
	case "batchInsert":
		return cc.batchInsert(stub, args)
	case "healthCheck":
		return cc.healthCheck(stub, args)
	default:
		return shim.Error(fmt.Sprintf("Unknown function: %s", function))
	}
}

// batchInsert - Simple batch insert for CouchDB exported data
func (cc *SimpleBatchChaincode) batchInsert(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Expecting 1 argument: JSON batch data")
	}

	startTime := time.Now()

	// Parse batch data from dApp
	var batchData BatchData
	if err := json.Unmarshal([]byte(args[0]), &batchData); err != nil {
		return shim.Error(fmt.Sprintf("Failed to parse batch data: %s", err.Error()))
	}

	// Simple validation
	if len(batchData.Documents) == 0 {
		return shim.Error("No documents provided")
	}

	// Initialize result
	result := BatchResult{
		TotalDocs: len(batchData.Documents),
		Errors:    []string{},
	}

	// Process all documents
	for i, doc := range batchData.Documents {
		// Use _id from CouchDB export directly as key
		var key string
		if id, exists := doc["_id"]; exists {
			key = id.(string)
		} else {
			result.FailedDocs++
			result.Errors = append(result.Errors, fmt.Sprintf("Doc %d: missing _id", i))
			continue
		}

		// Convert document to JSON and store directly
		docBytes, err := json.Marshal(doc)
		if err != nil {
			result.FailedDocs++
			result.Errors = append(result.Errors, fmt.Sprintf("Doc %d: marshal error: %s", i, err.Error()))
			continue
		}

		// Store in CouchDB
		if err := stub.PutState(key, docBytes); err != nil {
			result.FailedDocs++
			result.Errors = append(result.Errors, fmt.Sprintf("Doc %d: storage error: %s", i, err.Error()))
			continue
		}

		result.SuccessfulDocs++
	}

	result.ProcessingTime = time.Since(startTime).String()

	// Return result
	resultBytes, _ := json.Marshal(result)
	return shim.Success(resultBytes)
}

// healthCheck - Simple health check
func (cc *SimpleBatchChaincode) healthCheck(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	response := map[string]interface{}{
		"status":    "OK",
		"chaincode": "SimpleBatchChaincode",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		"txId":      stub.GetTxID(),
	}

	responseBytes, _ := json.Marshal(response)
	return shim.Success(responseBytes)
}

func main() {
	err := shim.Start(new(SimpleBatchChaincode))
	if err != nil {
		fmt.Printf("Error starting SimpleBatchChaincode: %s", err)
	}
}
