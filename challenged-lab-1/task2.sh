export ZONE=us-east1-c
export REGION=us-east1
export NOMEINSTANCIA=nucleus-jumphost-152
export NOMEFIREWALL=grant-tcp-rule-138

#Set the defaults
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE


#Create file startup.sh

cat << EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '\$HOSTNAME'/' /var/www/html/index.nginx-debian.html
EOF

#create the load balancer template:

gcloud compute instance-templates create nucleus-instance-template \
   --region=$REGION \
   --network=default \
   --subnet=default \
   --tags=allow-health-check \
   --machine-type=e2-medium \
   --image-family=debian-11 \
   --image-project=debian-cloud \
  --metadata-from-file startup-script=startup.sh 



#Create a managed instance group based on the template:

gcloud compute instance-groups managed create nucleus-instance-group \
   --template=nucleus-instance-template --size=2 --zone=$ZONE


gcloud compute instance-groups set-named-ports nucleus-instance-group --named-ports=http:80 --zone $ZONE

#Create the fw-allow-health-check firewall rule.

gcloud compute firewall-rules create $NOMEFIREWALL \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80


#Now that the instances are up and running, set up a global static external IP address that your customers use to reach your load balancer:

gcloud compute addresses create nucleus-ipv4-1 \
  --ip-version=IPV4 \
  --global

Note the IPv4 address that was reserved:
gcloud compute addresses describe nucleus-ipv4-1 \
  --format="get(address)" \
  --global

Set up the load balanceR

#Create a health check for the load balancer:

gcloud compute health-checks create http nucleus-health-check \
  --port 80

#Create a backend service:

gcloud compute backend-services create nucleus-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=nucleus-health-check \
  --global

#Add your instance group as the backend to the backend service:

gcloud compute backend-services add-backend nucleus-backend-service \
  --instance-group=nucleus-instance-group \
  --instance-group-zone=$ZONE \
  --global



#Create a URL map to route the incoming requests to the default backend service:

gcloud compute url-maps create nucleus-web-map-http \
    --default-service nucleus-backend-service


#Create a target HTTP proxy to route requests to your URL map:

gcloud compute target-http-proxies create nucleus-proxy \
    --url-map nucleus-web-map-http

# for https
gcloud compute target-https-proxies create https-nucleus-proxy \
  --url-map=nucleus-web-map-http \
  --ssl-certificates=www-ssl-cert

#Create a global forwarding rule to route incoming requests to the proxy:

gcloud compute forwarding-rules create nucleus-http-content-rule \
   --address=nucleus-ipv4-1\
   --global \
   --target-http-proxy=nucleus-proxy \
   --ports=80


