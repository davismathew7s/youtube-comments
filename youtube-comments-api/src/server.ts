import express, { Request, Response } from 'express';
import bodyParser from 'body-parser';
import { Client } from 'cassandra-driver';
import { v4 as uuidv4 } from 'uuid';
import dotenv from 'dotenv';

// Load environment variables from .env file
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware to parse JSON bodies
app.use(bodyParser.json());

// Initialize ScyllaDB client using environment variables
const client = new Client({
  contactPoints: process.env.SCYLLA_CONTACT_POINTS?.split(',') || [],
  localDataCenter: process.env.SCYLLA_LOCAL_DATA_CENTER || '',
  credentials: {
    username: process.env.SCYLLA_USERNAME || '',
    password: process.env.SCYLLA_PASSWORD || '',
  },
  keyspace: process.env.SCYLLA_KEYSPACE || '',
});

// Connect to ScyllaDB and handle connection success/error
client.connect()
  .then(() => console.log('Connected to ScyllaDB'))
  .catch((err: Error) => console.error('Connection error:', err));

// Route to add a new comment
app.post('/comments', async (req: Request, res: Response): Promise<void> => {
  const { video_id, user_id, content } = req.body;

  // Validate required fields
  if (!video_id || !user_id || !content) {
    res.status(400).json({ error: 'video_id, user_id, and content are required' });
    return;
  }

  const comment_id = uuidv4(); // Generate unique comment ID
  const query = `
    INSERT INTO comments (video_id, comment_id, user_id, content, likes, replies_count, timestamp)
    VALUES (?, ?, ?, ?, 0, 0, toTimestamp(now()));
  `;

  try {
    // Execute the insert query
    await client.execute(query, [video_id, comment_id, user_id, content], { prepare: true });
    res.status(201).json({ message: 'Comment added', comment_id });
  } catch (err: any) {
    console.error("Error adding comment:", err);
    res.status(500).json({ error: 'An error occurred while adding the comment' });
  }
});

// Route to add a reply to a comment
app.post('/comments/:comment_id/replies', async (req: Request, res: Response): Promise<void> => {
  const { comment_id } = req.params;
  const { user_id, content } = req.body;

  // Validate required fields
  if (!comment_id || !user_id || !content) {
    res.status(400).json({ error: 'comment_id, user_id, and content are required' });
    return;
  }

  const reply_id = uuidv4(); // Generate unique reply ID
  const query = `
    INSERT INTO replies (reply_id, comment_id, user_id, content, timestamp)
    VALUES (?, ?, ?, ?, toTimestamp(now()));
  `;

  try {
    // Execute the insert query for reply
    await client.execute(query, [reply_id, comment_id, user_id, content], { prepare: true });
    res.status(201).json({ message: 'Reply added', reply_id });
  } catch (err: any) {
    console.error("Error adding reply:", err);
    res.status(500).json({ error: 'An error occurred while adding the reply' });
  }
});

// Route to update likes for a comment
app.put('/comments/:video_id/:comment_id/like', async (req: Request, res: Response): Promise<void> => {
  const { video_id, comment_id } = req.params;

  // Fetch the current number of likes
  const selectQuery = `
    SELECT likes FROM comments
    WHERE video_id = ? AND comment_id = ?;
  `;

  try {
    const result = await client.execute(selectQuery, [video_id, comment_id], { prepare: true });
    const currentLikes = result.rows[0]?.likes || 0;

    // Update the likes count
    const updateQuery = `
      UPDATE comments
      SET likes = ?
      WHERE video_id = ? AND comment_id = ?;
    `;
    await client.execute(updateQuery, [currentLikes + 1, video_id, comment_id], { prepare: true });

    res.status(200).json({ message: 'Like added' });
  } catch (err: any) {
    console.error("Error updating likes:", err);
    res.status(500).json({ error: 'An error occurred while updating likes' });
  }
});

// Route to fetch top comments based on a filter (newest or top)
app.get('/comments/top', async (req: Request, res: Response): Promise<void> => {
  const { video_id, filter, page = 1, limit = 10 } = req.query;

  // Validate the required parameter video_id
  if (!video_id) {
    res.status(400).json({ error: 'video_id is required' });
    return;
  }

  // Validate filter parameter
  const validFilters = ['newest', 'top'];
  if (filter && !validFilters.includes(filter as string)) {
    res.status(400).json({ error: `Invalid filter. Valid filters are: ${validFilters.join(', ')}` });
    return;
  }

  // Validate pagination parameters
  const pageNumber = parseInt(page as string, 10);
  const limitNumber = parseInt(limit as string, 10);

  if (isNaN(pageNumber) || pageNumber <= 0) {
    res.status(400).json({ error: 'Invalid page number' });
    return;
  }

  if (isNaN(limitNumber) || limitNumber <= 0) {
    res.status(400).json({ error: 'Invalid limit' });
    return;
  }

  const query = `
    SELECT * FROM youtube_comments.comments
    WHERE video_id = ? LIMIT ?
    ALLOW FILTERING;
  `;

  const countQuery = `
    SELECT COUNT(*) FROM youtube_comments.comments
    WHERE video_id = ?;
  `;

  try {
    // Fetch comments with pagination
    const result = await client.execute(query, [video_id, limitNumber], { prepare: true });

    // Fetch the total count of comments for the given video
    const countResult = await client.execute(countQuery, [video_id], { prepare: true });
    const totalComments = countResult.rows[0]?.count || 0;

    let sortedComments = result.rows;

    // Apply sorting based on filter
    if (filter === 'top') {
      sortedComments = sortedComments
        .sort((a, b) => b.likes - a.likes || b.timestamp - a.timestamp)
        .slice(0, limitNumber);
    } else if (filter === 'newest') {
      sortedComments = sortedComments
        .sort((a, b) => b.timestamp - a.timestamp)
        .slice(0, limitNumber);
    }

    // Return the response
    res.status(200).json({
      video_id,
      total_comments: totalComments,
      current_page: pageNumber,
      total_pages: Math.ceil(totalComments / limitNumber),
      comments: sortedComments,
    });
  } catch (err: any) {
    console.error("Error fetching top comments:", err);
    res.status(500).json({ error: 'An error occurred while fetching top comments' });
  }
});

// Start the server and listen on the specified port
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
