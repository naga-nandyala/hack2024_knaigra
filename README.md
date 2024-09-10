# KnAIGra - AI assisted Industrial Knowledge Graphs

This repo contains artifacts related to this hack  
https://hackbox.microsoft.com/hackathons/hackathon2024/project/62912


### Setting up the Infrastructure
1. Setup Azure Login details using Azure CLI:

    ```bash
    az login --tenant "<tenant_id>"
    az account set -s "<subscription_id>"
    ```

1. Clone the repository:
   
    ```
    git clone https://github.com/naga-nandyala/hack2024_knaigra.git
    ```


1. Change the directory to the `infra` folder of the sample:

    ```bash
    cd ./hack2024_knaigra/infra
    ```

1. Rename the [.envtemplate](./.envtemplate) file to `.env` and fill in the necessary environment variables. Here is the detailed explanation of the environment variables:
   
1. Review [setup-infra.sh](./infra/setup-infra.sh) script and see if you want to adjust the derived naming of variable names of Azure/Fabric resources.

1. Run the [setup-infra.sh](./infra/setup-infra.sh) script:

    ```bash
    ./setup-infra.sh
    ```