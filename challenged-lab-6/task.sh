# Set up and Configure a Cloud Environment in Google Cloud: Challenge Lab 
# https://www.qwiklabs.com/focuses/10603?parent=catalog

# NOTE: Create all resources in the us-west1 region and us-west1-c zone, unless otherwise directed.

# Task 1: Create development VPC manually
    - Go to Navigation menu > VPC Network > Create VPC Network
        - Name: griffin-dev-vpc
        - Subnet creation mode: Custom
            - New subnet:
                - Name: griffin-dev-wp
                - Region: us-east1
                - IP address range: 192.168.16.0/20
            - Click Add subnet:
                - Name: griffin-dev-mgmt
                - Region: us-east1
                - IP address range: 192.168.32.0/20
        - CREATE

gcloud compute networks create griffin-dev-vpc --project=qwiklabs-gcp-03-91390eeabfd7 --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional
gcloud compute networks subnets create griffin-dev-wp --project=qwiklabs-gcp-03-91390eeabfd7 --range=192.168.16.0/20 --stack-type=IPV4_ONLY --network=griffin-dev-vpc --region=us-west1
gcloud compute networks subnets create griffin-dev-mgmt --project=qwiklabs-gcp-03-91390eeabfd7 --range=192.168.32.0/20 --stack-type=IPV4_ONLY --network=griffin-dev-vpc --region=us-west1

# Task 2: Create production VPC using Deployment Manager
    - Open Cloud Shell
        - run: gsutil cp -r gs://cloud-training/gsp321/dm ~/
        - run: cd dm
        - run: nano prod-network.yaml
            - replace SET_REGION to us-east1
            - save
        - run: gcloud deployment-manager deployments create griffin-prod --config prod-network.yaml
    - Confirm deployment (Open Deployment Manager)




# Task 3: Create bastion host
    - Go to Compute Engine > VM instances > Create
        - Name: bastion
        - Region: us-east1
        - Expand Management, security, disk, networking, sole tenany section
            - Networking section: 
                - Network tags: bastion
                - Network interfaces: 
                    - setup two network interfaces
                        - griffin-dev-mgmt
                        - griffin-prod-mgmt
            - Create
          
    gcloud compute instances create bastion --project=qwiklabs-gcp-03-91390eeabfd7 --zone=us-west1-c --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=griffin-dev-mgmt --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=griffin-prod-mgmt --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --service-account=191062127232-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --create-disk=auto-delete=yes,boot=yes,device-name=bastion,image=projects/debian-cloud/global/images/debian-12-bookworm-v20240415,mode=rw,size=10,type=projects/qwiklabs-gcp-03-91390eeabfd7/zones/us-west1-c/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any
      


    - Go to VPC network > Firewall
        - Create firewall rule
            - Name: allow-bastion-dev-ssh
            - Network: griffin-dev-vpc
            - Target tags: bastion
            - Source IP ranges: 192.168.32.0/20
            - Protols and ports: check tcp > fill with 22
            - Create
          #Code SSH
            gcloud compute --project=qwiklabs-gcp-03-91390eeabfd7 firewall-rules create allow-bastion-dev-ssh --direction=INGRESS --priority=1000 --network=griffin-dev-vpc --action=ALLOW --rules=tcp:22 --source-ranges=192.168.32.0/20 --target-tags=bastion

        - Create second firewall rule
            - Name: allow-bastion-prod-ssh
            - Network: griffin-prod-vpc
            - Target tags: bastion
            - Source IP ranges: 192.168.48.0/20
            - Protols and ports: check tcp > fill with 22
            - Create
        #Code SSH
            gcloud compute --project=qwiklabs-gcp-03-91390eeabfd7 firewall-rules create allow-bastion-prod-ssh --direction=INGRESS --priority=1000 --network=griffin-prod-vpc --action=ALLOW --rules=tcp:22 --source-ranges=192.168.48.0/20 --target-tags=bastion

# Task 4: Create and configure Cloud SQL Instance
    - Go to SQL > Create instance > Choose MySQL
        - Name: griffin-dev-db
        - Root password: <your_password> example: 123456
        - Region: us-east1
        - Zone: us-east1-c
        - Create
    - Wait instance updated
    - Connect to this instance section > Click Connect using Cloud Shell
    - Go to Cloud shell
        - run: gcloud sql connect griffin-dev-db --user=root --quiet
        - enter your sql root password
        - *in sql console*
            - run: CREATE DATABASE wordpress;
            - run: GRANT ALL PRIVILEGES ON wordpress.* TO "wp_user"@"%" IDENTIFIED BY "stormwind_rules";
            - run: FLUSH PRIVILEGES;
            - type exit to quit

# Task 5: Create Kubernetes cluster
    - Go to Kubernetes Engine > Clusters > Create cluster
        - Name: griffin-dev
        - Zone: us-east1-c
        - Click default-pool dropdown (left pane)
            - Number of nodes: 2
        - Click Nodes
            - Series: E2
            - Machine type:  e2-standard-4
        - Click Networking tab (left pane)
            - Network: griffin-dev-vpc 
            - Node subnet: griffin-dev-wp
        - CREATE
        #Code SSH

gcloud beta container --project "qwiklabs-gcp-03-91390eeabfd7" clusters create "griffin-dev" --no-enable-basic-auth --cluster-version "1.28.7-gke.1026000" --release-channel "regular" --machine-type "e2-standard-4" --image-type "COS_CONTAINERD" --disk-type "pd-balanced" --disk-size "100" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "2" --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM --enable-ip-alias --network "projects/qwiklabs-gcp-01-6d3955a11b44/global/networks/griffin-dev-vpc" --subnetwork "projects/qwiklabs-gcp-01-6d3955a11b44/regions/us-east1/subnetworks/griffin-dev-wp" --no-enable-intra-node-visibility --default-max-pods-per-node "110" --security-posture=standard --workload-vulnerability-scanning=disabled --no-enable-master-authorized-networks --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --binauthz-evaluation-mode=DISABLED --enable-managed-prometheus --enable-shielded-nodes --node-locations "us-west1-c"
gcloud beta container --project "qwiklabs-gcp-03-91390eeabfd7" clusters create "griffin-dev" --no-enable-basic-auth --cluster-version "1.28.7-gke.1026000" --release-channel "regular" --machine-type "e2-standard-4" --image-type "COS_CONTAINERD" --disk-type "pd-balanced" --disk-size "100" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "2" --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM --enable-ip-alias --network "projects/qwiklabs-gcp-03-91390eeabfd7/global/networks/griffin-dev-vpc" --subnetwork "projects/qwiklabs-gcp-03-91390eeabfd7/regions/us-west1/subnetworks/griffin-dev-wp" --no-enable-intra-node-visibility --default-max-pods-per-node "110" --security-posture=standard --workload-vulnerability-scanning=disabled --no-enable-master-authorized-networks --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --binauthz-evaluation-mode=DISABLED --enable-managed-prometheus --enable-shielded-nodes --node-locations "us-west1-c"

# Task 6: Prepare the Kubernetes cluster
    - Open Cloud Shell
        - run: gsutil cp -r gs://cloud-training/gsp321/wp-k8s ~/
        - run: cd ~/wp-k8s
        - run: nano wp-env.yaml
            - Replace <username_goes_here> to wp_user 
            - Replace <password_goes_here> to stormwind_rules
            - Save
        - Connect to Kubernetes cluster > Run in Cloud Shell
            - run: gcloud container clusters get-credentials griffin-dev --zone=us-west1-c
            - run: kubectl apply -f wp-env.yaml
            - run: gcloud iam service-accounts keys create key.json --iam-account=cloud-sql-proxy@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
            - run: kubectl create secret generic cloudsql-instance-credentials --from-file key.json

# Task 7: Create a WordPress deployment
    - Open Cloud Shell
        - run: cd ~/wp-k8s
        - Edit wp-deployment.yaml (choose one between sheel or editor)
            - with shell :
                - run: nano wp-deployment.yaml
                    - Replace YOUR_SQL_INSTANCE with SQL Instance connection name (SQL >  Connect to this instance > Look at connection name)
                    - Save
            - with editor :
                - Click 'Open Editor'
                - Go to file wp-k8s/wp-deployment.yaml
                - Find YOUR_SQL_INSTANCE with Ctrl + F
                - Replace YOUR_SQL_INSTANCE with SQL Instance connection name (SQL >  Connect to this instance > Look at connection name)
                - File > Save
                - Go back to Cloud Shell
        - run: kubectl create -f wp-deployment.yaml
        - run: kubectl create -f wp-service.yaml
    - Go to Kubernetes Engine > Service & Ingress > Click Endpoints (and copy for next task)
        - Tips: If your website failed to showed (database issue) you can still complete this lab

# Task 8: Enable monitoring
    - Go to Monitoring (Navigation > Monitoring) > Uptime checks (left pane) > CREATE UPTIME CHECK
        - Title: WordPress Uptime
        - Protocol: HTTP
        - Resource Type: URL
        - Hostname: <YOUR-WORDPRESS_ENDPOINT>
        - Path: /
    - Click TEST > SAVE
        # Tips: If TEST failed (caused by issue in task 7) you can SAVE directly (Click button NEXT until you able to click SAVE button)

# Task 9: Provide access for an additional engineer
    - Go to IAM & Admin > IAM
    - Click +ADD
        - New members: Paste your second user account
        - In Role dropdown, select Project > Editor
    - SAVE