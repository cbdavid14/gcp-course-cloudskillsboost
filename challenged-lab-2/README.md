# Build a Secure Google Cloud Network: Challenge Lab

Set Up an App Dev Environment on Google Cloud: Challenge Lab

## Task 1. Create a bucket

You need to create a bucket called Bucket Name for the storage of the photographs. Ensure the resource is created in the REGION region and ZONE zone.

## Task 2. Create a Pub/Sub topic

Create a Pub/Sub topic called Topic Name for the Cloud Function to send messages.

## Task 3. Create the thumbnail Cloud Function

Create a Cloud Function Cloud Function Name that will to create a thumbnail from an image added to the Bucket Name bucket. Ensure the Cloud Function is using the 2nd Generation environment. Ensure the resource is created in the REGION region and ZONE zone.

Create a Cloud Function "xxxxxx"

Note: The Cloud Function is required to executes every time an object is created in the bucket created in Task 1. During the process Cloud Function may request permission to enable APIs. Please enable each of the required APIs as requested.

- Make sure you set the Entry point (Function to execute) to Cloud Function Name and Trigger to Cloud Storage.

- Add the following code to the index.js:#