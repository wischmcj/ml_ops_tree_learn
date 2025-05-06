# ml_ops_tree_learn


# Run Book
IaC code for creating a gpu droplet in Digital Ocean, running TreeLearn's pre-weighted UNet and exporting the data back to a local location. This allows for the TreeLearn model to be run on a GPU with 250GB of ram, using user requested weights and an arbitrary lidar scan, with just three easy steps!
 
1. Perform the setup steps described below. In summarry, you'll configure your DigitalOcean account, install two command line tools, and configure the pipeline variables for the model run. 
2. Run the below to create the droplet, install all of the necessary prerequisites, download published model weights and upload the lidar scan you've provided 
  ```bash
    tofu apply -var-file=inputs.tfvars
   ```
3. Open the DigitalOcean web UI and access your droplet's web console. Run the below to run the model pipeline:
  ```bash
    cd /mnt/tlvol/TreeLearn/
    python3 run_pipeline.py
   ```
# Set-up

## Prerequsites
  The entire set-up process can be done in ~15/20 minutes barring any unforseen install errors. To run this code, you will need:
  1. Terraform installed on your local machine
  2. Ansible installed on your local machine 
  3. A digital ocean account and API token
  4. Permission to create GPU droplets on DigitalOcean

### DigitalOcean 
#### API Token (~5 min)
Follow these instructions to create an API token to allow ssh access to DigitalOcean. https://cloud.digitalocean.com/account/api/tokens/new

Upload your ssh key to DigitalOcean. You can do that here https://cloud.digitalocean.com/account/security?i=c84be4. Also, Make a copy of the ssh fingerprint as you need it later.

#### GPU Droplets  (~3 min)
GPU droplets cost ~$3.50 an hour as of writing. This cost is nominal for us, given the TreeLearn pipeline runs in 10-20 minutes. However, DigitalOcean disables these droplets by default to protect consumers from unintended costs. All that means is that you'll need to submit a ticket to DigitalOcean for permission to create them. 

Just log in to the DigitalOcean web UI, and select 'GPU Droplets' from the menu on the left. When you try to create one, you'll be prompted to create one of the above mentioned tickets. These tickets are generally resolved in 24-48 hours.

### Install Terraform (~5 min)
Follow the install instructions here: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

### Install Ansible (~5 min)
Follow the install instructions here: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html


## Variables 
High level, the variables we'll set below consist of:

    - DigitalOcean connection data and data storage options
    - Model inputs (including data preparation settings, initial weights, input data)
    - Output directory structure
  

# Variable Glossary
Copy inputs.tfvars.json.dist to inputs.tfvars.json, and fill out the values. You can find some guidance on how to do so below.

## Digital Ocean - Configuration 
  Only the first two of these 'need' to be updated, the rest can remain on their default setting. 
- `do_token`: Digital Ocean API token required for authentication and resource management
- `do_pvt_key`: File path to private SSH key used for authenticating with Digital Ocean droplets
- `do_region`: Digital Ocean datacenter region where resources will be deployed (e.g. nyc2)
- `do_host_type`: GPU instance type specification for the droplet. This determines the number of GPUs and the size of the storage available for your droplet. Here is a [list of options](https://slugs.do-api.dev/), See the DigitalOcean documentation for more detail.
- `droplet_image`: Base image used for creating the droplet. The default setting comes with Nvidia drivers installed. (e.g. gpu-h100x1-base)

## Digital Ocean - Optional 
For the first run, leave these blank. In the future, you can create snapshots of your Droplet and/or the Volume containing the uploaded data to avoid having to repeat the setup each time.
- `droplet_snapshot_id`: Optional ID of a droplet snapshot to restore from instead of base image
- `volume_id`: Optional ID of an existing volume to attach to the droplet
- `volume_snapshot_id`: Optional ID of a volume snapshot to restore from when creating new volume

## Local Machine Details
These are used to copy the results files to your local machine (See [copy_results.sh](ansible/playbooks/roles/tree_learner/templates/copy_results.sh))
- `local_ip`: IP address of your local machine to allow file copying via ssh
- `local_user`: Username on your local machine to allow file copying via ssh
- `local_data_dir`: Directory on local machine to copy the results files to

## TreeLearn - File Configuration
The defaults for below ought to work well for the majority of cases.  
- `root_vol`: Mount point where the data volume will be attached on the droplet. The default should be fine.
- `config_path`: Location to generate the TreeLearn pipeline configuration file (via [this template](ansible/playbooks/roles/tree_learner/templates/pipeline.yaml))
- `weights_path`: Path to which pre-trained neural network model weights should be downloaded (see 'weights_url')
- `save_format`: Output format for the processed data (e.g. 'las')
- `return_type`: Specifies type of point cloud data to return (e.g. 'original')
- `tree_learn_repo`: GitHub repository URL for the TreeLearn codebase
- `example_forest_url`: URL for downloading sample forest data

## TreeLearn - Run Customization
These are your key variables, they define the data you want run through the model, what portions of the pipeline to run and the pre-determined weights you would like to use to run the model. 
- `forest_data_path`: Directory containing the forest LiDAR point cloud data
- `forest_file_name`: Name of the specific forest LiDAR file to process
- `start_at`: Defines the pipeline entry point. This can be used after pipeline failures to avoid having to rerun data. e.g. if the pipeline fails after creating the tiles due to a typo. I can fix said typo, then restart the pipeline with 'start_at' = "pw_preds".
- `weights_url`: URL for downloading the pre-trained model weights. See the appendix for available weights files.


### Practical Guide 
Just fill out the needed values in inputs.tfvars. This file should be passed when the process is called, as shown below:
  ```bash
    tofu plan -var-file=inputs.tfvars 
    tofu apply -var-file=inputs.tfvars
   ```

The variables will then flow through to the [pipeline configuration file](ansible/playbooks/roles/tree_learner/templates/pipeline.yaml)[(see docs)](https://github.com/ecker-lab/TreeLearn/blob/main/docs/segmentation_pipeline.md#explanation-of-some-args-for-running-the-pipeline), informing the run of the model.


### Files 

The following variable files exist: 

- `inputs.tfvars.json`: Where the user changes variables 
  - Main variable definitions file that is passed to OpenTofu via the CLI 
- `inputs.tf`: 
  - Defines which variables can be passed in inputs.tfvars and, by extension, the pipeline.
- `ansible/playbooks/roles/tree_learner/vars/main.yml`: 
  - Defines available variables and sensible defaults for the ansible role
- `ansible/playbooks/roles/tree_learner/templates/pipeline.yaml`: 
  - Pipeline configuration template; populated with the user input model parameters and processing options 

### Flow of Variables

The flow of variables from user input through to the pipeline proceeds as follows

1. User updates variables as desired in inputs.tfvars.json
2. User provides variables via command line when running either:
   a. OpenTofu:
        ```bash
        tofu apply -var-file=inputs.tfvars.json
        ```
   b. Ansible
        ```bash
        tofu apply -var-file=inputs.tfvars.json
        ```

3. Variables are passed to ansible playbooks in main.tf:
    arguably, these commands ought to be run via command line. This is just more convenient.
   ```hcl
        ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook
                          -u root
                          -i '${element(digitalocean_droplet.tree_learner.*.ipv4_address, count.index)},'"
                          --private-key ${var.do_pvt_key}
                          -e 'pub_key=${var.do_pub_key}'
                          ansible/playbooks/apt_setup.yml
   ```

4. Ansible roles (tree_learner) receive variables in vars/main.yml:
   - Sets paths for weights, data, repositories
   - Configures forest data locations
   - Sets root volume and local machine details

5. Final pipeline configuration, pipeline.yaml, is populated by ansible pipeline:
   - Variables templated into YAML structure
   - Sets model parameters, data paths
   - Configures processing pipeline with received variables

# Apendix 
## Weights Options
data url for small_tree
// "data_url": "https://data.goettingen-research-online.de/file.xhtml?persistentId=doi:10.25625/VPMPID/TYZJ4E&version=7.0"
finetuned weights 
// "data_url": "https://data.goettingen-research-online.de/file.xhtml?persistentId=doi:10.25625/VPMPID/8CIIW0&version=7.0"
diverse training weights 
// "data_url": "https://data.goettingen-research-online.de/file.xhtml?persistentId=doi:10.25625/VPMPID/C1AHQW&version=7.0"
