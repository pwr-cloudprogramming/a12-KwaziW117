Title
Author: Katarzyna Wysokińśka 266615
Group:
Date of Project: 24.06.2024


Architecture Description

The infrastructure includes:
EC2 Instance: Hosts the web server and the application.
IAM Roles and Policies: Ensures secure access to AWS resources.
DynamoDB: Stores game results and player rankings.
Cognito: Manages user authentication and authorization.
S3: Stores static assets for the application.
Lambda Functions: Processes game results and updates player rankings.
API Gateway: Provides RESTful API endpoints for interacting with the Lambda functions.


Configured AWS Services

EC2 Instance
![image](https://github.com/pwr-cloudprogramming/a12-KwaziW117/assets/101679098/1d91630f-bab3-40d6-b421-586d1e0d78c1)

IAM Roles and Policies
![image](https://github.com/pwr-cloudprogramming/a12-KwaziW117/assets/101679098/698b026a-51bd-4166-81f0-c1d5ce478119)


DynamoDB Tables
![image](https://github.com/pwr-cloudprogramming/a12-KwaziW117/assets/101679098/6bda6d32-4119-46f2-b431-2f9f0d91a224)
![image](https://github.com/pwr-cloudprogramming/a12-KwaziW117/assets/101679098/9bf694d8-e14e-4dab-aa35-178af35c620b)


S3 Bucket
![image](https://github.com/pwr-cloudprogramming/a12-KwaziW117/assets/101679098/59fd6e16-ec3f-4970-be50-6976a592d005)

Lambda Functions
![image](https://github.com/pwr-cloudprogramming/a12-KwaziW117/assets/101679098/952dbbac-258d-4167-ba3f-12e5141de979)


API Gateway
![image](https://github.com/pwr-cloudprogramming/a12-KwaziW117/assets/101679098/c885245e-a052-42b4-8ab2-fbe0399697a7)


Application Running
![image](https://github.com/pwr-cloudprogramming/a12-KwaziW117/assets/101679098/81999239-2d3a-4624-a39b-71f790598c14)


Reflections
What did I learn?
During this project, I learned how to integrate various AWS services to build a full-stack application. I gained hands-on experience with:


Managing access and permissions using IAM roles and policies.
Using DynamoDB for scalable and reliable data storage.
Automating backend logic using AWS Lambda.
Exposing backend functionality through RESTful APIs with API Gateway.
Hosting static assets on S3 and ensuring they are securely accessible.

What obstacles did you overcome?
One of the main challenges was configuring the IAM roles and policies to ensure that the different AWS services could interact securely and correctly. Understanding the least privilege principle and applying it appropriately was crucial. Additionally, setting up the correct permissions for the Lambda function to access DynamoDB and ensuring the API Gateway integration worked seamlessly required careful attention to detail.

Was that something that surprised you?
I was pleasantly surprised by how integrated and cohesive the AWS ecosystem is. The services are designed to work together, and once you understand the basics, you can build complex infrastructures relatively quickly. However, the vast array of services and configurations can be overwhelming initially, highlighting the importance of thorough documentation and planning.

Why did you choose the particular type of database?
I chose DynamoDB for this project due to its scalability, reliability, and ease of integration with other AWS services. DynamoDB is a fully managed NoSQL database that can handle large amounts of data with low latency, making it ideal for applications like this where performance and scalability are critical. Additionally, DynamoDB's flexible data model allowed for easy storage and retrieval of game results and player rankings.
