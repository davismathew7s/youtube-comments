CREATE KEYSPACE IF NOT EXISTS youtube_comments WITH REPLICATION = {
  'class' : 'SimpleStrategy',
  'replication_factor' : 3
};

USE youtube_comments;

-- Table for storing comments
CREATE TABLE youtube_comments.comments (
    video_id uuid,
    comment_id uuid,
    likes int,
    content text,
    replies_count int,
    timestamp timestamp,
    user_id uuid,
    PRIMARY KEY (video_id, comment_id)
) WITH CLUSTERING ORDER BY (comment_id ASC);

-- Table for storing replies to comments
CREATE TABLE IF NOT EXISTS replies (
  reply_id UUID,
  comment_id UUID,
  user_id UUID,
  content TEXT,
  timestamp TIMESTAMP,
  PRIMARY KEY (comment_id, reply_id)
);



















youtube_comments> CREATE TABLE IF NOT EXISTS youtube_comments.comments (
  video_id UUID,
  comment_id UUID,
  user_id UUID,
  content TEXT,
  likes INT,
  replies_count INT,
  timestamp TIMESTAMP,
  PRIMARY KEY (video_id, likes, timestamp)
);

CREATE TABLE replies (
  reply_id UUID PRIMARY KEY,
  comment_id UUID,
  user_id UUID,
  content TEXT,
  timestamp TIMESTAMP
);


cqlsh node-0.aws-us-east-1.34c2059d0d3d0294b6e0.clusters.scylla.cloud -u scylla -p Jhcl8sdi2n4XRUo
Connected to d2f24613-9859-4969-abb2-667b02d173e4 at node-0.aws-us-east-1.34c2059d0d3d0294b6e0.clusters.scylla.cloud:9042.
[cqlsh 5.0.1 | Cassandra 3.0.8 | CQL spec 3.3.1 | Native protocol v4]
Use HELP for help.
scylla@cqlsh> CREATE KEYSPACE youtube_comments
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3};
scylla@cqlsh> USE youtube_comments;
scylla@cqlsh:youtube_comments> CREATE TABLE comments (
    comment_id UUID PRIMARY KEY,
    user_id UUID,
    content TEXT,
    likes INT,
    replies_count INT,
    timestamp TIMESTAMP
);
scylla@cqlsh:youtube_comments> CREATE TABLE replies (
    reply_id UUID PRIMARY KEY,
    comment_id UUID,
    user_id UUID,
    content TEXT,
    timestamp TIMESTAMP
);
scylla@cqlsh:youtube_comments> DESCRIBE KEYSPACES;

system_schema  system_replicated_keys         system_distributed
system_auth    system_distributed_everywhere  system_traces     
system         youtube_comments             

scylla@cqlsh:youtube_comments> CREATE TABLE comments (
    video_id UUID,              -- Partition key
    comment_id UUID,            -- Clustering key
    user_id UUID,
    content TEXT,
    likes INT,
    replies_count INT,
    timestamp TIMESTAMP,
    PRIMARY KEY (video_id, comment_id)  -- video_id is the partition key, comment_id is the clustering key 
);
AlreadyExists: Table 'youtube_comments.comments' already exists
scylla@cqlsh:youtube_comments> SELECT * FROM comments
WHERE video_id = 1234
ORDER BY likes DESC
LIMIT 10;
InvalidRequest: Error from server: code=2200 [Invalid query] message="Unrecognized name video_id"
scylla@cqlsh:youtube_comments> DROP TABLE comments;

CREATE TABLE comments (
    video_id UUID,
    comment_id UUID,
    user_id UUID,
    content TEXT,
    likes INT,
    replies_count INT,
    timestamp TIMESTAMP,
    PRIMARY KEY (video_id, comment_id)
);
scylla@cqlsh:youtube_comments> SELECT * FROM comments
WHERE video_id = 1234
ORDER BY likes DESC
LIMIT 10;
InvalidRequest: Error from server: code=2200 [Invalid query] message="Invalid INTEGER constant (1234) for "video_id" of type uuid"
scylla@cqlsh:youtube_comments> SELECT * FROM comments
WHERE video_id = uuid()  -- Replace `uuid()` with the actual UUID value
ORDER BY likes DESC
LIMIT 10;
InvalidRequest: Error from server: code=2200 [Invalid query] message="Order by is currently only supported on the clustered columns of the PRIMARY KEY, got likes"
scylla@cqlsh:youtube_comments> SELECT * FROM comments
WHERE video_id = 550e8400-e29b-41d4-a716-446655440000
ORDER BY likes DESC
LIMIT 10;
InvalidRequest: Error from server: code=2200 [Invalid query] message="Order by is currently only supported on the clustered columns of the PRIMARY KEY, got likes"
scylla@cqlsh:youtube_comments> DROP TABLE comments;

CREATE TABLE comments (
    video_id UUID,              -- Partition key
    comment_id UUID,            -- Clustering key 1
    likes INT,                  -- Clustering key 2
    user_id UUID,
    content TEXT,
    replies_count INT,
    timestamp TIMESTAMP,
    PRIMARY KEY (video_id, comment_id, likes)
) WITH CLUSTERING ORDER BY (comment_id ASC, likes DESC);
scylla@cqlsh:youtube_comments> CREATE MATERIALIZED VIEW comments_by_likes AS
    SELECT * FROM comments
    WHERE video_id IS NOT NULL AND likes IS NOT NULL
    PRIMARY KEY (video_id, likes, comment_id)
    WITH CLUSTERING ORDER BY (likes DESC, comment_id ASC);
InvalidRequest: Error from server: code=2200 [Invalid query] message="Primary key column 'comment_id' is required to be filtered by 'IS NOT NULL'"
scylla@cqlsh:youtube_comments> SELECT * FROM comments_by_likes
WHERE video_id = 550e8400-e29b-41d4-a716-446655440000
LIMIT 10;
InvalidRequest: Error from server: code=2200 [Invalid query] message="unconfigured table comments_by_likes"
scylla@cqlsh:youtube_comments> DROP TABLE IF EXISTS comments;

CREATE TABLE comments (
    video_id UUID,              -- Partition key
    comment_id UUID,            -- Clustering key 1
    likes INT,                  -- Clustering key 2
    user_id UUID,
    content TEXT,
    replies_count INT,
    timestamp TIMESTAMP,
    PRIMARY KEY (video_id, comment_id, likes)
) WITH CLUSTERING ORDER BY (comment_id ASC, likes DESC);
scylla@cqlsh:youtube_comments> CREATE MATERIALIZED VIEW comments_by_likes AS
    SELECT video_id, comment_id, likes, user_id, content, replies_count, timestamp
    FROM comments
    WHERE video_id IS NOT NULL
      AND likes IS NOT NULL
      AND comment_id IS NOT NULL
    PRIMARY KEY (video_id, likes, comment_id)
    WITH CLUSTERING ORDER BY (likes DESC, comment_id ASC);
scylla@cqlsh:youtube_comments> SELECT * FROM comments_by_likes
WHERE video_id = 550e8400-e29b-41d4-a716-446655440000
LIMIT 10;

 video_id | likes | comment_id | content | replies_count | timestamp | user_id
----------+-------+------------+---------+---------------+-----------+---------

(0 rows)
scylla@cqlsh:youtube_comments> SELECT * FROM comments WHERE video_id = 550e8400-e29b-41d4-a716-446655440000;

 video_id | comment_id | likes | content | replies_count | timestamp | user_id
----------+------------+-------+---------+---------------+-----------+---------

(0 rows)
scylla@cqlsh:youtube_comments> INSERT INTO comments (video_id, comment_id, likes, user_id, content, replies_count, timestamp)
VALUES (550e8400-e29b-41d4-a716-446655440000, 
        e02d0d84-27c3-4f1f-a6e5-c349aafeba89, 
        100, 
        a12b5678-c9d0-1234-5678-e2345678abcd, 
        'This is a sample comment.', 
        5, 
        toTimestamp(now()));
scylla@cqlsh:youtube_comments> SELECT * FROM comments_by_likes 
WHERE video_id = 550e8400-e29b-41d4-a716-446655440000 
LIMIT 10;

 video_id                             | likes | comment_id                           | content                   | replies_count | timestamp                       | user_id
--------------------------------------+-------+--------------------------------------+---------------------------+---------------+---------------------------------+--------------------------------------
 550e8400-e29b-41d4-a716-446655440000 |   100 | e02d0d84-27c3-4f1f-a6e5-c349aafeba89 | This is a sample comment. |             5 | 2024-12-13 10:40:18.959000+0000 | a12b5678-c9d0-1234-5678-e2345678abcd

(1 rows)
scylla@cqlsh:youtube_comments> CREATE TABLE IF NOT EXISTS youtube_comments.comments (
  video_id UUID,
  comment_id UUID,
  user_id UUID,
  content TEXT,
  likes INT,
  replies_count INT,
  timestamp TIMESTAMP,
  PRIMARY KEY (video_id, likes DESC, timestamp DESC)  -- likes and timestamp are now part of the clusterin);key
SyntaxException: line 9:31 : Missing ')'
scylla@cqlsh:youtube_comments> CREATE TABLE IF NOT EXISTS youtube_comments.comments (
  video_id UUID,
  comment_id UUID,
  user_id UUID,
  content TEXT,
  likes INT,
  replies_count INT,
  timestamp TIMESTAMP,
  PRIMARY KEY (video_id, likes DESC, timestamp DESC)  -- likes and timestamp are now part of the clusterin);key
SyntaxException: line 9:31 : Missing ')'
scylla@cqlsh:youtube_comments> CREATE TABLE IF NOT EXISTS youtube_comments.comments (
  video_id UUID,
  comment_id UUID,
  user_id UUID,
  content TEXT,
  likes INT,
  replies_count INT,
  timestamp TIMESTAMP,
  PRIMARY KEY (video_id, likes DESC, timestamp DESC)  -- likes and timestamp are now part of the clusterin);key
SyntaxException: line 9:31 : Missing ')'
scylla@cqlsh:youtube_comments> CREATE TABLE IF NOT EXISTS youtube_comments.comments (
  video_id UUID,               CREATE TABLE IF NOT EXISTS youtube_comments.comments (
  video_id UUID,D,
  comment_id UUID,
  user_id UUID,
  content TEXT,
  likes INT,unt INT,
  replies_count INT,P,
  timestamp TIMESTAMP,d, likes DESC, timestamp DESC) 
  PRIMARY KEY (video_id, likes DESC, timestamp DESC) 
);
SyntaxException: line 9:31 : Missing ')'
scylla@cqlsh:youtube_comments> CREATE TABLE IF NOT EXISTS youtube_comments.comments (
  video_id UUID,               CREATE TABLE IF NOT EXISTS youtube_comments.comments (
  video_id UUID,D,
  comment_id UUID,
  user_id UUID,
  content TEXT,
  likes INT,unt INT,
  replies_count INT,P,
  timestamp TIMESTAMP,d, likes DESC, timestamp DESC) 
  PRIMARY KEY (video_id, likes DESC, timestamp DESC) 
);
SyntaxException: line 9:31 : Missing ')'
scylla@cqlsh:youtube_comments> CREATE TABLE IF NOT EXISTS youtube_comments.comments (
  video_id UUID,
  comment_id UUID,
  user_id UUID,
  content TEXT,
  likes INT,
  replies_count INT,
  timestamp TIMESTAMP,
  PRIMARY KEY (video_id, likes DESC, timestamp DESC)
);
SyntaxException: line 9:31 : Missing ')'
scylla@cqlsh:youtube_comments> CREATE TABLE IF NOT EXISTS youtube_comments.comments (
  video_id UUID,
  comment_id UUID,
  user_id UUID,
  content TEXT,
  likes INT,
  replies_count INT,
  timestamp TIMESTAMP,
  PRIMARY KEY (video_id, likes, timestamp)
);
scylla@cqlsh:youtube_comments> SELECT * FROM comments_by_likes  WHERE video_id = 550e8400-e29b-41d4-a716-446655440000  LIMIT 10;                                                                                    

 video_id                             | likes | comment_id                           | content                   | replies_count | timestamp                       | user_id
--------------------------------------+-------+--------------------------------------+---------------------------+---------------+---------------------------------+--------------------------------------
 550e8400-e29b-41d4-a716-446655440000 |   100 | e02d0d84-27c3-4f1f-a6e5-c349aafeba89 | This is a sample comment. |             5 | 2024-12-13 10:40:18.959000+0000 | a12b5678-c9d0-1234-5678-e2345678abcd

(1 rows)
scylla@cqlsh:youtube_comments> CREATE TABLE IF NOT EXISTS youtube_comments.comments (
  video_id UUID,
  comment_id UUID,
  user_id UUID,
  content TEXT,
  likes INT,
  replies_count INT,
  timestamp TIMESTAMP,
  PRIMARY KEY (video_id, likes, timestamp)
) WITH CLUSTERING ORDER BY (likes DESC, timestamp DESC);
scylla@cqlsh:youtube_comments> SELECT * FROM youtube_comments.comments
WHERE video_id = 550e8400-e29b-41d4-a716-446655440000
ORDER BY likes DESC, timestamp DESC
LIMIT 10;
InvalidRequest: Error from server: code=2200 [Invalid query] message="Order by is currently only supported on the clustered columns of the PRIMARY KEY, got timestamp"
scylla@cqlsh:youtube_comments> SELECT * FROM youtube_comments.comments
WHERE video_id = 550e8400-e29b-41d4-a716-446655440000
LIMIT 10;

 video_id                             | comment_id                           | likes | content                   | replies_count | timestamp                       | user_id
--------------------------------------+--------------------------------------+-------+---------------------------+---------------+---------------------------------+--------------------------------------
 550e8400-e29b-41d4-a716-446655440000 | e02d0d84-27c3-4f1f-a6e5-c349aafeba89 |   100 | This is a sample comment. |             5 | 2024-12-13 10:40:18.959000+0000 | a12b5678-c9d0-1234-5678-e2345678abcd

(1 rows)
scylla@cqlsh:youtube_comments> SELECT * FROM youtube_comments.comments WHERE video_id = 550e8400-e29b-41d4-a716-446655440000 LIMIT 10;

 video_id                             | comment_id                           | likes | content                   | replies_count | timestamp                       | user_id
--------------------------------------+--------------------------------------+-------+---------------------------+---------------+---------------------------------+--------------------------------------
 550e8400-e29b-41d4-a716-446655440000 | 9676347a-4884-45a1-9739-0f00c0d8be54 |     0 |                Nice video |             0 | 2024-12-13 11:47:37.960000+0000 | 550e8400-e29b-41d4-a716-446655440001
 550e8400-e29b-41d4-a716-446655440000 | e02d0d84-27c3-4f1f-a6e5-c349aafeba89 |   100 | This is a sample comment. |             5 | 2024-12-13 10:40:18.959000+0000 | a12b5678-c9d0-1234-5678-e2345678abcd

(2 rows)
scylla@cqlsh:youtube_comments> SELECT * FROM youtube_comments.comments WHERE video_id = 550e8400-e29b-41d4-a716-446655440000 LIMIT 10;
NoHostAvailable: 
scylla@cqlsh:youtube_comments> SELECT * FROM youtube_comments.comments WHERE video_id = 550e8400-e29b-41d4-a716-446655440000 LIMIT 10;
NoHostAvailable: 