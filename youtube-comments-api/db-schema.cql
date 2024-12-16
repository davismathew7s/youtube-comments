CREATE KEYSPACE IF NOT EXISTS youtube_comments WITH REPLICATION = {
  'class' : 'SimpleStrategy',
  'replication_factor' : 3
};

USE youtube_comments;

-- Table for storing comments
CREATE TABLE IF NOT EXISTS youtube_comments.comments (
  video_id UUID,
  comment_id UUID,
  user_id UUID,
  content TEXT,
  likes INT,
  replies_count INT,
  timestamp TIMESTAMP,
  PRIMARY KEY (video_id, likes, timestamp, comment_id)
) WITH CLUSTERING ORDER BY (likes DESC, timestamp DESC, comment_id ASC);

-- Table for storing replies to comments
CREATE TABLE IF NOT EXISTS replies (
  reply_id UUID,
  comment_id UUID,
  user_id UUID,
  content TEXT,
  timestamp TIMESTAMP,
  PRIMARY KEY (comment_id, reply_id)
);