export ZONE=us-east1-c
export REGION=us-east1
export NOMEINSTANCIA=nucleus-jumphost-152
export NOMEFIREWALL=grant-tcp-rule-138

#Set the defaults
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

#Creating the instance
gcloud compute instances create $NOMEINSTANCIA --machine-type=e2-micro --zone=$ZONE