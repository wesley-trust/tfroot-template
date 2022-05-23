package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	//"github.com/stretchr/testify/assert"
)

func TestApplyDefault(t *testing.T) {
	t.Parallel()

	// Root folder where Terraform files should be (relative to the test folder)
	rootFolder := "../"

	// Remove Backend Terraform definition so local state is used
	backendFile := "../backend.tf"
	os.Remove(backendFile)

	// Generate a random deployment name for the test to prevent a naming conflict
	uniqueID := random.UniqueId()
	testREF := "Testing"
	serviceDeployment := testREF + "-" + uniqueID

	// Define variables
	//locations := []string{"UK South"}

	// Concatenate expected resource group name
	//resourceGroupName := "Services-Test-UKS-" + serviceDeployment + "-rg"

	// Enable retryable error
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{

		// The path to where the Terraform code is located
		TerraformDir: rootFolder,

		// Variables to pass to the Terraform code using -var options
		Vars: map[string]interface{}{
			"service_deployment": serviceDeployment,
		},
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`. Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables
	//output := terraform.Output(t, terraformOptions, "resourceGroupName")
	//assert.Equal(t, resourceGroupName, output)
}
