# ml_ops_tree_learn
IaC code for creating a gpu droplet in Digital Ocean, running TreeLearn's pre-weighted UNet and exporting the data back to a local location


# Variables 

## Practical Guide 
Just fill out the needed values in inputs.tfvars. This file should be passed when the process is called, as shown below:
`tofu plan -var-file=inputs.tfvars `
`tofu apply -var-file=inputs.tfvars `
The variables will then flow through to the [pipeline configuration file](ansible/playbooks/roles/tree_learner/templates/pipeline.yaml)[(see docs)](https://github.com/ecker-lab/TreeLearn/blob/main/docs/segmentation_pipeline.md#explanation-of-some-args-for-running-the-pipeline), informing the run of the model



## Details 

The following variable files exist: 

- `inputs.tfvars`: Where the user changes variables 
  - Main variable definitions file that is passed to OpenTofu via the CLI 
- `inputs.tf`: Defines which variables can be passed in inputs.tfvars for OpenTofu
  - Variable declarations and type definitions that specify the expected format and structure of input variables
- `ansible/playbooks/roles/tree_learner/vars/main.yml`: 
  - Defines which variables can be passed to the tree_learner ansible role from terraform
- `ansible/playbooks/roles/tree_learner/templates/pipeline.yaml`: 
  - Pipeline configuration template that receives variables to set model parameters and processing options


The flow of variables from user input through to the pipeline proceeds as follows

1. User provides variables via command line when running tofu:
   ```bash
   tofu apply -var-file="inputs.tfvars"
   ```

2. Variables are declared and typed in inputs.tf:
   - Digital Ocean settings (token, keys, region etc)
   - Pipeline configuration (file paths, volumes)
   - Droplet configuration (instance names, images)

3. Values are defined in inputs.tfvars:
   - Credentials and access tokens
   - Local machine details (IP, user, data directory)
   - Forest data configuration (file name, paths)

4. Variables are passed to ansible playbooks in main.tf:
   ```hcl
   -e 'forest_file_name=${var.forest_file_name}'
   ```

5. Ansible roles (tree_learner) receive variables in vars/main.yml:
   - Sets paths for weights, data, repositories
   - Configures forest data locations
   - Sets root volume and local machine details

6. Final pipeline configuration in pipeline.yaml:
   - Variables templated into YAML structure
   - Sets model parameters, data paths
   - Configures processing pipeline with received variables
