# Devops kijanikiosk IAM least privilege design.


IAM (Identity and Access Management) controls who can access resources in the cloud.

For the retail service system, a deployment role can be created for the application deployment process. This role would only have permission to upload new application files and restart the application service.

The role would not have permissions to delete databases, modify networking settings, or manage other system resources. This follows the principle of least privilege by giving the application only the permissions it needs to perform its task, while limiting access to other sensitive parts of the system.
