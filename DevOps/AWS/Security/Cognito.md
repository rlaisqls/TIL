
Amazon Cognito is an identity platform for web and mobile apps. It’s a user directory, an authentication server, and an authorization service for OAuth 2.0 access tokens and AWS credentials.

With Amazon Cognito, you can authenticate and authorize users from the built-in user directory, from your enterprise directory, and from consumer identity providers like Google and Facebook.

## User pools

<img src="https://github.com/rlaisqls/TIL/assets/81006587/1f09d9aa-2e83-4a0c-afe4-9b76a9928802" height=400px>

- Create a user pool when you want to authenticate and authorize users to your app or API.

- User pools are a user directory with both self-service and administrator-driven user creation, management, and authentication. Your user pool can be an independent directory and OIDC identity provider (IdP), and an intermediate service provider (SP) to third-party providers of workforce and customer identities.
  
- Your organization's SAML 2.0 and OIDC IdPs bring workforce identities into Cognito and your app. The public OAuth 2.0 identity stores Amazon, Google, Apple and Facebook bring customer identities.

- User pools don’t require integration with an identity pool. From a user pool, you can issue authenticated JSON web tokens (JWTs) directly to an app, a web server, or an API.

### Provision of user pools

- Membership registration and login service
- Built-in custom web UI for user login
- Support for social login via Facebook, Google, Amazon, Apple, and login via SAML and OpenID Connect (OIDC) in user pools
- Managing Users and User Profiles
- Provides security features such as multi-factor authentication (MFA), credential verification, account theft protection, and phone and email verification
- Customizing the authentication process of Cognito using AWS Lambda triggers

## Identity pools

<img src="https://github.com/rlaisqls/TIL/assets/81006587/ef28dec0-5997-4e76-a08d-77b76a906e76" height=400px>

- Set up an Amazon Cognito identity pool when you want to authorize authenticated or anonymous users to access your AWS resources.

- An identity pool issues AWS credentials for your app to serve resources to users. You can authenticate users with a trusted identity provider, like a user pool or a SAML 2.0 service. It can also optionally issue credentials for guest users. Identity pools use both role-based and attribute-based access control to manage your users’ authorization to access your AWS resources.

- Identity pools don’t require integration with a user pool. An identity pool can accept authenticated claims directly from both workforce and consumer identity providers.

### An Amazon Cognito user pool and identity pool used together

In the diagram that begins this topic, you use Amazon Cognito to authenticate your user and then grant them access to an AWS service.

Your app user signs in through a user pool and receives OAuth 2.0 tokens.

Your app exchanges a user pool token with an identity pool for temporary AWS credentials that you can use with AWS APIs and the AWS Command Line Interface (AWS CLI).

Your app assigns the credentials session to your user, and delivers authorized access to AWS services like Amazon S3 and Amazon DynamoDB.

---

**reference**
- https://docs.aws.amazon.com/cognito/latest/developerguide/what-is-amazon-cognito.html
- https://www.youtube.com/watch?v=SiCQtRmvQBY&t=1s