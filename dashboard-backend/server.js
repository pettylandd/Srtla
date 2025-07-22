const express = require('express');
const cors = require('cors');
const fetch = require('node-fetch');
const app = express();
const RECEIVER_API = process.env.RECEIVER_API || 'http://receiver:8080';

app.use(cors());
app.use(express.json());

let users = [{ username: "admin", password: "adminpass", role: "admin" }];

function authenticate(req, res, next) {
  const token = req.headers['authorization'];
  if (token === "Bearer mocktoken") {
    next();
  } else {
    res.status(401).json({ error: "Unauthorized" });
  }
}

app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  const user = users.find(u => u.username === username && u.password === password);
  if (user) {
    res.json({ token: "mocktoken", user: { username: user.username, role: user.role } });
  } else {
    res.status(401).json({ error: "Invalid credentials" });
  }
});

// Proxy all /api/receiver/* requests to the real receiver API, with login required
app.use('/api/receiver', authenticate, async (req, res) => {
  const url = `${RECEIVER_API}${req.url}`;
  try {
    const receiverRes = await fetch(url, {
      method: req.method,
      headers: { 'Content-Type': 'application/json' },
      body: ['POST', 'PUT', 'PATCH'].includes(req.method) ? JSON.stringify(req.body) : undefined
    });
    const data = await receiverRes.text();
    res.status(receiverRes.status).send(data);
  } catch (e) {
    res.status(502).json({ error: "Failed to reach SRTLA receiver backend" });
  }
});

app.get('/', (req, res) => {
  res.send('Dashboard API running!');
});

app.listen(8080, () => console.log('Dashboard API running on :8080'));
