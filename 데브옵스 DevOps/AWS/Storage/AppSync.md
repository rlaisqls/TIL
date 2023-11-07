# AppSync

<img width="649" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/cd94639f-0937-4141-a540-b7e3acf6cd2e">

AppSync는 AWS에서 제공하는 Managed GraphQL 서비스이다. 즉, 서버리스의 형태로 GraphQL 백엔드를 개발할 수 있는 서비스이다.

AppSyn 를 사용하지 않고도 AWS Lambda 등을 활용하여 GraphQL 백엔드를 구축하는 것이 가능했으나, 이 경우에는 Lambda 메모리 사이즈, 콜드스타트, DataSource와의 통신, 인증된 유저 토큰 처리 등등 고민해야하고 직접 개발해야하는 것들이 더 많았다. 그러나 AppSync 를 활용하면 GraphQL 스키마를 작성하고 스키마의 각각의 필드에 대한 resolvers 를 작성하는 것만으로도 GraphQL 엔드포인트를 생성할 수 있다.

### Resolver

AppSync에서는 resolver를 VTL이라는 자바 기반 템플릿 언어으로 작성한다. 

AppSync에서는 request와 response할 시에 호출될 resolver를 각각 정의해줘야 한다. 따라서 각각의 필드에 대하여 request mapping template과 response mapping template이 한쌍을 이뤄 하나의 resolver를 이루게 된다. AppSync 에서 사용할 수 있는 resolver 타입은 2종류가 있다.

<img width="348" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/d33d6eb5-c5d7-4cc2-b849-2022e2221e69">

- **Unit Resolver**
  - 간단한 형태로 구성되어있고, 한 개의 데이터소스(DynamoDB, RDS 등)와 연결시켜서 request 와 response 를 처리해주는 resolver이다.
- **Pipeline Resolver**
  - 백엔드 API 를 개발하다보면 Unit resolvers로 해결되지 않는 복잡한 로직들이 많다. 예를 들면, Friendship 테이블에서 두 사람이 친구로 등록된 경우에만 해당 로직을 처리한다던지, 포인트를 사용하여 결제하려는 경우 Point 테이블에서 유저의 포인트가 충분한 경우에만 결제 로직을 처리한다던지 등 여러가지 상황들이 있다. 이럴 때 Pipeline resolvers를 활용할 수 있다.

    <img width="216" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/b9afea3b-60ce-46dd-b73b-d43aef0db918">
  
  Pipeline resolver 타입은 하나하나의 `request mapping template` + `response mapping template` 쌍을 Function으로 등록하여 사용한다. 이 Function은 다른 resolver 에서도 사용할 수 있어서, 공통적인 로직을 만들어두고 다양한 resolver에서 사용하는 패턴 등의 활용이 가능합니다.

### Scalar Types

알고 계시듯이 GraphQL은 쿼리언어 자체적으로 type check을 처리해준다. 그러므로 request 나 response 에서 주고받는 데이터 각각이 Int 타입인지 String 타입인지를 개발자가 고려할 필요가 없다.

GraphQL에서 정의하고 있는 일반적인 Scalar 타입은 아래와 같다.

- ID
- String
- Int
- Float
- Double

이에 추가적으로 AppSync에서 제공하는 Scalar 타입을 활용하면 더욱 편리하게 API를 개발할 수 있다.

- AWSDate
- AWSTime
- AWSDateTime
- AWSTimestamp
- AWSEmail
- AWSJSON
- AWSURL
- AWSPhone
- AWSIPAddress

이러한 Scalar type 을 활용하여 커스텀 타입을 지정할 수 있다.

```go
type User {
  id: ID!
  name: String!
  phone: AWSPhone!
  email: AWSEmail!
  myPageUrl: AWSURL!
  createdAt: AWSDateTime!
}
```


## 예시

appsync를 생성해보자.

우선 프로젝트 디렉토리를 구성한다.

```bash
mkdir appsync-tutorial
cd appsync-tutorial

touch serverless.yml
mkdir schema
mkdir resolvers
```

그리고 먼저 serverless-appsync-plugin를 설치해준다.

```bash
yarn add serverless-appsync-plugin
```

### Schema

이제 스키마를 작성해보자. `serverless-appsync-plugin`에서 Schema stitching 이라는 기능을 제공하고 있기때문에 모듈별로 분리해서 스키마를 작성하는 것이 가능하다.

```bash
cd schema
touch user.graphql
touch post.graphql
touch like.graphql
```

3가지 스키마 파일을 생성했다면 각각 아래와 같이 스키마를 작성해준다.

```go
// user.graphql
type User {
    userId: ID!
    name: String!
    email: AWSEmail!
    posts: [Post!]!
    createdAt: AWSDateTime!
}

input CreateInputUser {
    name: String!
    email: AWSEmail!
}

type Query {
    listUser: [User!]!
    getUser(userId: ID!): User
}

type Mutation {
    createUser(input: CreateInputUser!): User
}

// post.graphql
type Post {
    postId: ID!
    user: User!
    title: String!
    content: String!
    likes: [Like!]!
    createdAt: AWSDateTime!
}

input CreatePostInput {
    userId: ID!
    title: String!
    content: String!
}

type Query {
    listPost: [Post!]!
    listPostByUser(userId: ID!): [Post!]!
    getPost(postId: ID!): Post
}

type Mutation {
    createPost(input: CreatePostInput!): Post
}

type Subscription {
    /*
    * Subscription을 사용하면 AppSync에서 Mutation이 실행될 때 관련 데이터를 클라이언트에게
    *  실시간으로 전달해준다. 여기에서는 createPost가 실행되면 onNewPostCreated라는
    *  subscription을 등록한 클라이언트에게 값을 실시간으로 전달해주게 된다.
    */
    onNewPostCreated: Post @aws_subscribe(mutations: ["createPost"])
}


// like.graphql
type Like {
    likeId: ID!
    userId: ID!
    postId: ID!
    createdAt: AWSDateTime!
}

type Query {
    listLike(postId: ID!): [Like!]!
}

type Mutation {
    likePost(userId: ID!, postId: ID!): Like
    cancelLikePost(likeId: ID!): Like
}

type Subscription {
    /*
    * 특정한 포스트 ID에 대한 subscription 을 받아온다.
    */
    onPostLiked(postId: ID!): Like @aws_subscribe(mutations: ["likePost"])
    onPostLikeCanceled(postId: ID!): Like @aws_subscribe(mutations: ["cancelLikePost"])
}
```

### Resolvers

resolvers 폴더로 이동하여 resolver 파일을 생성해보자.

파일명은 serverless-appsync-plugin에서 default로 인식하는 `{type}.{field}.request.vtl`, `{type}.{field}.respose.vtl`로 지정하였고, 내용은 [이곳](https://github.com/twkiiim/appsync-tutorial)에 있는 내용을 기반으로 작성했다.

```bash
cd ../resolvers

# User
touch User.posts.response.vtl
touch User.posts.request.vtl
touch Query.getUser.request.vtl
touch Query.getUser.response.vtl
touch Query.listUser.request.vtl
touch Query.listUser.response.vtl
touch Mutation.createUser.request.vtl
touch Mutation.createUser.response.vtl

# Post
touch Post.user.request.vtl
touch Post.user.response.vtl
touch Post.likes.request.vtl
touch Post.likes.response.vtl
touch Query.getPost.request.vtl
touch Query.getPost.response.vtl
touch Query.listPost.request.vtl
touch Query.listPost.response.vtl
touch Query.listPostByUser.request.vtl
touch Query.listPostByUser.response.vtl
touch Mutation.createPost.request.vtl
touch Mutation.createPost.response.vtl

# Like
touch Query.listLike.request.vtl
touch Query.listLike.response.vtl
touch Mutation.likePost.request.vtl
touch Mutation.likePost.response.vtl
touch Mutation.cancelLikePost.request.vtl
touch Mutation.cancelLikePost.response.vtl
```

### serverless.yml

위에서 본 모든 리소스들이 `serverless.yml`에 마지막으로 정리된다.

```yaml
service: classmethod-appsync-tutorial

frameworkVersion: ">=1.48.0 <2.0.0"

provider:
  name: aws
  runtime: nodejs10.x
  stage: dev
  region: ap-northeast-2

plugins:
  - serverless-appsync-plugin

custom:
  appSync:
    name: AppSyncTutorialByClassmethod
    authenticationType: AMAZON_COGNITO_USER_POOLS
    userPoolConfig:
      awsRegion: ap-northeast-2
      defaultAction: ALLOW
      userPoolId: { Ref: AppSyncTutorialUserPool }
    region: ap-northeast-2
    mappingTemplatesLocation: resolvers
    mappingTemplates:
      
      # User
      - 
        type: User
        field: posts
        dataSource: Post
      - 
        type: Query
        field: listUser
        dataSource: User
      - 
        type: Query
        field: getUser
        dataSource: User
      - 
        type: Mutation
        field: createUser
        dataSource: User

      # Post
      - 
        type: Post
        field: user
        dataSource: User
      - 
        type: Post
        field: likes
        dataSource: Like
      -
        type: Query
        field: listPost
        dataSource: Post
      - 
        type: Query
        field: listPostByUser
        dataSource: Post
      - 
        type: Query
        field: getPost
        dataSource: Post
      - 
        type: Mutation
        field: createPost
        dataSource: Post

      # Like
      - 
        type: Query
        field: listLike
        dataSource: Like
      - 
        type: Mutation
        field: likePost
        dataSource: Like
      - 
        type: Mutation
        field: cancelLikePost
        dataSource: Like

        
    schema:
      - schema/user.graphql
      - schema/post.graphql
      - schema/like.graphql
    
    #serviceRole: # if not provided, a default role is generated
    dataSources:
      - type: AMAZON_DYNAMODB
        name: User
        description: User Table
        config:
          tableName: User
          iamRoleStatements:
            - Effect: Allow
              Action:
                - dynamodb:*
              Resource:
                - arn:aws:dynamodb:${self:provider.region}:*:table/User
                - arn:aws:dynamodb:${self:provider.region}:*:table/User/*

      - type: AMAZON_DYNAMODB
        name: Post
        description: Post Table
        config:
          tableName: Post
          iamRoleStatements:
            - Effect: Allow
              Action:
                - dynamodb:*
              Resource:
                - arn:aws:dynamodb:${self:provider.region}:*:table/Post
                - arn:aws:dynamodb:${self:provider.region}:*:table/Post/*
      
      - type: AMAZON_DYNAMODB
        name: Like
        description: Like Table
        config:
          tableName: Like
          iamRoleStatements:
            - Effect: Allow
              Action:
                - dynamodb:*
              Resource:
                - arn:aws:dynamodb:${self:provider.region}:*:table/Like
                - arn:aws:dynamodb:${self:provider.region}:*:table/Like/*


resources:
  Resources:
    AppSyncTutorialUserPool:
      Type: AWS::Cognito::UserPool
      DeletionPolicy: Retain
      Properties:
        UserPoolName: AppSyncTutorialUserPool
        AutoVerifiedAttributes:
          - email
        Policies:
          PasswordPolicy:
            MinimumLength: 8
        UsernameAttributes:
          - email

    AppSyncTutorialUserPoolWebClient:
      Type: AWS::Cognito::UserPoolClient
      Properties:
          ClientName: Web
          GenerateSecret: false
          RefreshTokenValidity: 30
          UserPoolId: { Ref: AppSyncTutorialUserPool }


    UserTable:
      Type: AWS::DynamoDB::Table
      Properties:
        TableName: User
        KeySchema:
          -
            AttributeName: userId
            KeyType: HASH
        AttributeDefinitions:
          -
            AttributeName: userId
            AttributeType: S
        BillingMode: PAY_PER_REQUEST

    PostTable:
      Type: AWS::DynamoDB::Table
      Properties:
        TableName: Post
        KeySchema:
          -
            AttributeName: postId
            KeyType: HASH
        AttributeDefinitions:
          -
            AttributeName: postId
            AttributeType: S
          -
            AttributeName: userId
            AttributeType: S
        BillingMode: PAY_PER_REQUEST

        # GSI - userId
        GlobalSecondaryIndexes:
          -
            IndexName: userId-index
            KeySchema:
              - AttributeName: userId
                KeyType: HASH
              - AttributeName: postId
                KeyType: RANGE
            Projection:
              ProjectionType: ALL

    LikeTable:
      Type: AWS::DynamoDB::Table
      Properties:
        TableName: Like
        KeySchema:
          - AttributeName: likeId
            KeyType: HASH
        AttributeDefinitions:
          - AttributeName: likeId
            AttributeType: S
          - AttributeName: userId
            AttributeType: S
          - AttributeName: postId
            AttributeType: S
        BillingMode: PAY_PER_REQUEST

        GlobalSecondaryIndexes:

          # GSI - userId
          - IndexName: userId-index
            KeySchema:
              -
                AttributeName: userId
                KeyType: HASH
              -
                AttributeName: likeId
                KeyType: RANGE
            Projection:
              ProjectionType: ALL
          
          # GSI - postId
          - IndexName: postId-index
            KeySchema:
              -
                AttributeName: postId
                KeyType: HASH
              -
                AttributeName: likeId
                KeyType: RANGE
            Projection:
              ProjectionType: ALL
```

### 배포하기

```bash
serverless deploy -v
```

프로젝트 디렉토리에서 이 명령어를 치면 CloudFormation을 통해 배포가 시작된다.

---
참고
- https://docs.aws.amazon.com/appsync/latest/devguide/resolver-mapping-template-reference-programming-guide.html
- https://docs.aws.amazon.com/appsync/latest/devguide/real-time-data.html
- https://github.com/twkiiim/appsync-tutorial
- https://medium.com/@wesselsbernd/bff-back-end-for-front-end-architecture-as-of-may-2019-5d09b913a8ed
- https://www.youtube.com/watch?v=rjiiNpJzOYk