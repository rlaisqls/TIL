
If you are getting the HTTP 403 (Forbidden) error or the error message no basic auth credentials when trying to pull an image from ECR you are most likely doing so without logging into it first.

This is going to happen if we are running a Kubernetes cluster on EC2 instances instead of using EKS. To be able to authenticate before pulling images on Kubernetes we need to use the imagePullSecrets attribute that's going to reference the secret containing the credentials.

To get the ECR credentials (assuming our instance profile allow us to do it) we can use the following AWS CLI command: