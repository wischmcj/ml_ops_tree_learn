# connect to do notes 
cp /media/penguaman/code/code/CodesAndSuch/digital_ocean/* ~/.ssh/
╭─penguaman at penguaputer in /media/penguaman/code/code/ActualCode/ml_ops_tree_learn on main✘✘✘ 25-05-04 - 15:16:55
╰─⠠⠵ ssh-add ~/.ssh/id_rsa_digitalocean


# ml_ops_tree_learn
IaC code for creating a gpu droplet in Digital Ocean, running TreeLearn's pre-weighted UNet and exporting the data back to a local location


# Variables 

## Practical Guide 
Just fill out the needed values in inputs.tfvars. This file should be passed when the process is called, as shown below:
  ```bash
    tofu plan -var-file=inputs.tfvars 
    tofu apply -var-file=inputs.tfvars
   ```

The variables will then flow through to the [pipeline configuration file](ansible/playbooks/roles/tree_learner/templates/pipeline.yaml)[(see docs)](https://github.com/ecker-lab/TreeLearn/blob/main/docs/segmentation_pipeline.md#explanation-of-some-args-for-running-the-pipeline), informing the run of the model

High level, the variables are used to define:

    - DigitalOcean connection data and data storage options
    - Model inputs (including data preparation settings, initial weights, input data)
    - Outpur directory structure

## Files 

The following variable files exist: 

- `inputs.tfvars.json`: Where the user changes variables 
  - Main variable definitions file that is passed to OpenTofu via the CLI 
- `inputs.tf`: 
  - Defines which variables can be passed in inputs.tfvars and, by extension, the pipeline.
- `ansible/playbooks/roles/tree_learner/vars/main.yml`: 
  - Defines available variables and sensible defaults for the ansible role
- `ansible/playbooks/roles/tree_learner/templates/pipeline.yaml`: 
  - Pipeline configuration template; populated with the user input model parameters and processing options 

## Process

The flow of variables from user input through to the pipeline proceeds as follows

1. User updates variables as desired in inputs.tfvars.json
2. User provides variables via command line when running either:
   1. OpenTofu:
        ```bash
        tofu apply -var-file=inputs.tfvars.json
        ```
   3. Ansible
        ```bash
        tofu apply -var-file=inputs.tfvars.json
        ```
    w
3. Variables are passed to ansible playbooks in main.tf:
   ```hcl
   -e 'forest_file_name=${var.forest_file_name}'
   ```

4. Ansible roles (tree_learner) receive variables in vars/main.yml:
   - Sets paths for weights, data, repositories
   - Configures forest data locations
   - Sets root volume and local machine details

5. Final pipeline configuration in pipeline.yaml:
   - Variables templated into YAML structure
   - Sets model parameters, data paths
   - Configures processing pipeline with received variables
