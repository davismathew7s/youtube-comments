# YouTube Comments API

This project provides a RESTful API for handling YouTube-style comments and replies. It allows users to post comments, reply to comments, like comments, and fetch the top comments for a specific video. The backend uses **ScyllaDB** (a Cassandra-compatible database) for storing comments and replies.

## Features

- Add a new comment to a video.
- Add replies to existing comments.
- Update the number of likes for a comment.
- Fetch top comments based on likes or newest.
- Expose endpoints to manage comments and replies.

## Prerequisites

Before running the project, ensure you have the following installed:

- **Node.js** (v14 or higher)
- **npm** (v6 or higher)
- **ScyllaDB** (locally or remotely accessible)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/davismathew7s/youtube-comments.git
cd youtube-comments/youtube-comments-api
```

### 2. Install Dependencies

Run the following command to install the necessary dependencies:

```bash
npm install
```

### 3. Set Up Environment Variables

Create a `.env` file in the root of your project with the following content:

```
SCYLLA_CONTACT_POINTS=localhost:9042
SCYLLA_LOCAL_DATA_CENTER=datacenter1
SCYLLA_USERNAME=your-username
SCYLLA_PASSWORD=your-password
SCYLLA_KEYSPACE=youtube_comments
PORT=3000
```

- Replace `localhost:9042` with your ScyllaDB contact points.
- Update `your-username`, `your-password`, and `youtube_comments` to match your ScyllaDB credentials and keyspace.

### 4. Create the Database Schema

You need to create the necessary tables in your ScyllaDB instance. Run the following `db-schema.cql` file to set up the keyspace and tables.

```cql
-- Create Keyspace
CREATE KEYSPACE IF NOT EXISTS youtube_comments WITH REPLICATION = {
  'class' : 'SimpleStrategy',
  'replication_factor' : 3
};

USE youtube_comments;

-- Table for storing comments
CREATE TABLE IF NOT EXISTS comments (
  video_id UUID,
  comment_id UUID,
  user_id UUID,
  content TEXT,
  likes INT,
  replies_count INT,
  timestamp TIMESTAMP,
  PRIMARY KEY (video_id, comment_id)
);

-- Table for storing replies to comments
CREATE TABLE IF NOT EXISTS replies (
  reply_id UUID,
  comment_id UUID,
  user_id UUID,
  content TEXT,
  timestamp TIMESTAMP,
  PRIMARY KEY (comment_id, reply_id)
);
```

### 5. Running the Project

To start the application, run the following command:

```bash
npx tsx src/server.ts
```

This will start the server on `http://localhost:3000` (or the port you specified in the `.env` file).

### 6. Test the API Endpoints

You can test the following API endpoints using Postman or any other API client.

#### Add a New Comment

**POST /comments**

**Request Body:**
```json
{
  "video_id": "f047b6d1-62e6-4c56-95d9-9d52a0b849d7",
  "user_id": "8b70d7b4-9e39-4566-8696-8e41f1593996",
  "content": "Great video!"
}
```

#### Add a Reply to a Comment

**POST /comments/:comment_id/replies**

**Request Body:**
```json
{
  "user_id": "3c40676b-4571-4cd1-bd0e-76c1a4a4c4a6",
  "content": "I agree, very informative!"
}
```

#### Update Likes for a Comment

**PUT /comments/:video_id/:comment_id/like**

No request body needed, just ensure `video_id` and `comment_id` are in the URL path.

#### Get Top Comments for a Video

**GET /comments/top?video_id=f047b6d1-62e6-4c56-95d9-9d52a0b849d7&page=1&limit=10**

You can optionally use a `filter` query parameter to get comments based on their order:
- `filter=newest` - fetches the most recent comments.
- `filter=top` - fetches comments with the most likes (default behavior).

### 7. API Response Format

All responses will be returned in JSON format, with a success or error message.

**Success Response Example:**
```json
{
  "message": "Comment added",
  "comment_id": "a4c90b0c-2dbe-46b5-8759-4de28fa12fe7"
}
```

**Error Response Example:**
```json
{
  "error": "video_id, user_id, and content are required"
}
```

### 8. Example Test Data

You can use the following test data for testing via Postman or any other API client.

#### Add a New Comment:

**POST /comments**
```json
{
  "video_id": "f047b6d1-62e6-4c56-95d9-9d52a0b849d7",
  "user_id": "8b70d7b4-9e39-4566-8696-8e41f1593996",
  "content": "Great video!"
}
```

#### Add a Reply:

**POST /comments/a4c90b0c-2dbe-46b5-8759-4de28fa12fe7/replies**
```json
{
  "user_id": "3c40676b-4571-4cd1-bd0e-76c1a4a4c4a6",
  "content": "I agree, very informative!"
}
```

#### Get Top Comments:

**GET /comments/top?video_id=f047b6d1-62e6-4c56-95d9-9d52a0b849d7**

## Conclusion

This API allows you to manage YouTube-style comments and replies with features like adding comments, replying to comments, liking comments, and fetching top comments. It uses ScyllaDB (Cassandra-compatible) for persistence and is written in TypeScript with Express.js for scalability and flexibility.

If you encounter any issues or have further questions, feel free to open an issue on GitHub.
