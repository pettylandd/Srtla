#!/bin/bash

set -e

# Ensure sudo is used
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo."
   exit 1
fi

# --- FRONTEND: Overwrite Dashboard React Files ---
echo "Overwriting frontend files in dashboard/..."

mkdir -p dashboard/public
mkdir -p dashboard/src/components

cat > dashboard/package.json <<'EOF'
{
  "name": "srtla-dashboard",
  "version": "2.0.0",
  "main": "src/index.js",
  "dependencies": {
    "react": "^18.3.0",
    "react-dom": "^18.3.0",
    "axios": "^1.6.0",
    "@mui/material": "^5.15.0",
    "@mui/icons-material": "^5.15.0",
    "@emotion/react": "^11.11.4",
    "@emotion/styled": "^11.11.4",
    "react-scripts": "^5.0.1"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build"
  }
}
EOF

cat > dashboard/public/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>SRTLA Receiver Dashboard</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
EOF

cat > dashboard/src/index.js <<'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);
EOF

cat > dashboard/src/App.js <<'EOF'
import React, { useState } from 'react';
import { CssBaseline, Container, Paper, Typography } from '@mui/material';
import Login from './components/Login';
import Dashboard from './components/Dashboard';

function App() {
  const [token, setToken] = useState(null);
  const [userRole, setUserRole] = useState(null);

  return (
    <CssBaseline>
      <Container maxWidth="md">
        <Paper elevation={3} sx={{ marginTop: 4, padding: 3 }}>
          <Typography variant="h3" align="center" sx={{ mb: 3 }}>SRTLA Receiver Dashboard</Typography>
          {!token
            ? <Login setToken={setToken} setUserRole={setUserRole} />
            : <Dashboard token={token} setToken={setToken} userRole={userRole} />
          }
        </Paper>
      </Container>
    </CssBaseline>
  );
}

export default App;
EOF

cat > dashboard/src/components/Login.js <<'EOF'
import React, { useState } from 'react';
import { TextField, Button, Alert, Box } from '@mui/material';
import axios from 'axios';

const API_BASE = process.env.REACT_APP_SRTLA_API || "http://localhost:8080";

export default function Login({ setToken, setUserRole }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    try {
      const { data } = await axios.post(`${API_BASE}/login`, { username, password });
      setToken(data.token);
      setUserRole(data.role);
    } catch (err) {
      setError('Invalid credentials');
    }
  };

  return (
    <Box component="form" onSubmit={handleSubmit} sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
      <TextField label="Username" value={username} onChange={e => setUsername(e.target.value)} />
      <TextField label="Password" type="password" value={password} onChange={e => setPassword(e.target.value)} />
      <Button variant="contained" type="submit">Login</Button>
      {error && <Alert severity="error">{error}</Alert>}
    </Box>
  );
}
EOF

cat > dashboard/src/components/Dashboard.js <<'EOF'
import React from 'react';
import StreamList from './StreamList';
import AdminPanel from './AdminPanel';
import { Button, Box } from '@mui/material';

export default function Dashboard({ token, setToken, userRole }) {
  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      <Button variant="outlined" sx={{ alignSelf: 'flex-end' }} onClick={() => setToken(null)}>Logout</Button>
      <StreamList token={token} />
      <AdminPanel token={token} userRole={userRole} />
    </Box>
  );
}
EOF

cat > dashboard/src/components/StreamList.js <<'EOF'
import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { Card, CardMedia, CardContent, Typography, Grid, Chip, Stack, CircularProgress } from '@mui/material';
import StreamControls from './StreamControls';

const API_BASE = process.env.REACT_APP_SRTLA_API || "http://localhost:8080";

export default function StreamList({ token }) {
  const [streams, setStreams] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    axios.get(`${API_BASE}/streams`, { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setStreams(res.data))
      .finally(() => setLoading(false));
  }, [token]);

  if (loading) return <CircularProgress />;
  if (!streams.length) return <Typography>No active streams.</Typography>;

  return (
    <>
      <Typography variant="h5" sx={{ mb: 2 }}>Active Streams</Typography>
      <Grid container spacing={2}>
        {streams.map(stream => (
          <Grid item xs={12} sm={6} key={stream.id}>
            <Card>
              <CardMedia
                component="img"
                height="140"
                image={stream.previewUrl || 'https://placehold.co/300x180?text=Preview'}
                alt={stream.name}
              />
              <CardContent>
                <Typography variant="h6">{stream.name}</Typography>
                <Stack direction="row" spacing={1} sx={{ mb: 1 }}>
                  <Chip label={stream.active ? "Active" : "Inactive"} color={stream.active ? "success" : "default"} />
                  <Chip label={`Bitrate: ${stream.bitrate} kbps`} />
                  <Chip label={`Latency: ${stream.latency} ms`} />
                  <Chip label={stream.recording ? "Recording" : "Not Recording"} color={stream.recording ? "warning" : "default"} />
                </Stack>
                <StreamControls stream={stream} token={token} />
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    </>
  );
}
EOF

cat > dashboard/src/components/StreamControls.js <<'EOF'
import React, { useState } from 'react';
import { Button, Stack, Snackbar } from '@mui/material';
import axios from 'axios';

const API_BASE = process.env.REACT_APP_SRTLA_API || "http://localhost:8080";

export default function StreamControls({ stream, token }) {
  const [snackbar, setSnackbar] = useState({ open: false, message: '' });

  const apiCall = async (endpoint) => {
    try {
      const res = await axios.post(endpoint, {}, { headers: { Authorization: `Bearer ${token}` } });
      setSnackbar({ open: true, message: res.data.message || 'Action complete.' });
    } catch (e) {
      setSnackbar({ open: true, message: "Action failed." });
    }
  };

  return (
    <>
      <Stack direction="row" spacing={2}>
        <Button
          variant="contained"
          color={stream.active ? "error" : "success"}
          onClick={() => apiCall(`${API_BASE}/streams/${stream.id}/${stream.active ? "end" : "start"}`)}
        >
          {stream.active ? "Stop" : "Start"}
        </Button>
        <Button variant="contained" color="warning" onClick={() => apiCall(`${API_BASE}/streams/${stream.id}/record`)}>
          Toggle Record
        </Button>
      </Stack>
      <Snackbar
        open={snackbar.open}
        autoHideDuration={2000}
        onClose={() => setSnackbar({ open: false, message: '' })}
        message={snackbar.message}
      />
    </>
  );
}
EOF

cat > dashboard/src/components/AdminPanel.js <<'EOF'
import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { Card, CardContent, Typography, Button, Chip, Stack, TextField, CircularProgress } from '@mui/material';

const API_BASE = process.env.REACT_APP_SRTLA_API || "http://localhost:8080";

export default function AdminPanel({ token, userRole }) {
  const [keys, setKeys] = useState([]);
  const [newKey, setNewKey] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    axios.get(`${API_BASE}/admin/keys`, { headers: { Authorization: `Bearer ${token}` } })
      .then(res => setKeys(res.data.streamKeys || []))
      .finally(() => setLoading(false));
  }, [token]);

  const createKey = async () => {
    if (!newKey) return;
    await axios.post(`${API_BASE}/admin/keys`, { key: newKey }, { headers: { Authorization: `Bearer ${token}` } });
    setKeys([...keys, { id: newKey, key: newKey }]);
    setNewKey('');
  };

  const deleteKey = async (id) => {
    await axios.delete(`${API_BASE}/admin/keys/${id}`, { headers: { Authorization: `Bearer ${token}` } });
    setKeys(keys.filter(k => k.id !== id));
  };

  if (loading) return <CircularProgress />;
  if (userRole !== "admin") return <Typography>Admin privileges required.</Typography>;

  return (
    <Card sx={{ mt: 4 }}>
      <CardContent>
        <Typography variant="h6">Admin Panel</Typography>
        <Typography>Stream Keys:</Typography>
        <Stack direction="row" spacing={1} sx={{ my: 1 }}>
          {keys.map(k => (
            <Chip
              key={k.id}
              label={k.key}
              color="primary"
              onDelete={() => deleteKey(k.id)}
              sx={{ cursor: "pointer" }}
            />
          ))}
        </Stack>
        <Stack direction="row" spacing={2}>
          <TextField label="New Key" value={newKey} onChange={e => setNewKey(e.target.value)} />
          <Button variant="contained" onClick={createKey}>Create Key</Button>
        </Stack>
      </CardContent>
    </Card>
  );
}
EOF

cat > dashboard/Dockerfile <<'EOF'
FROM node:18-alpine AS build
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# --- BACKEND: Create Node.js/Express API ---
echo "Creating backend API in dashboard-backend/..."

mkdir -p dashboard-backend

cat > dashboard-backend/server.js <<'EOF'
const express = require('express');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const app = express();
app.use(cors());
app.use(express.json());

const SECRET = 'supersecret'; // Change for production!

// --- Dummy Data ---
let streams = [
  { id: "1", name: "Stream One", active: true, bitrate: 2400, latency: 80, previewUrl: "", recording: false },
  { id: "2", name: "Stream Two", active: false, bitrate: 0, latency: 0, previewUrl: "", recording: false }
];
let keys = [{ id: "abc123", key: "abc123" }, { id: "def456", key: "def456" }];
let users = [{ username: "admin", password: "adminpass", role: "admin" }];

// --- Auth Middleware ---
function auth(req, res, next) {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) return res.status(401).json({ message: "No token" });
  try {
    req.user = jwt.verify(token, SECRET);
    next();
  } catch {
    res.status(403).json({ message: "Invalid token" });
  }
}

// --- Login Endpoint ---
app.post('/login', (req, res) => {
  const { username, password } = req.body;
  const found = users.find(u => u.username === username && u.password === password);
  if (!found) return res.status(401).json({ message: "Bad login" });
  const token = jwt.sign({ username, role: found.role }, SECRET, { expiresIn: '2h' });
  res.json({ token, role: found.role });
});

// --- Streams CRUD ---
app.get('/streams', auth, (req, res) => {
  res.json(streams);
});

app.post('/streams/:id/start', auth, (req, res) => {
  const stream = streams.find(s => s.id === req.params.id);
  if (stream) { stream.active = true; }
  res.json({ message: "Started", stream });
});

app.post('/streams/:id/end', auth, (req, res) => {
  const stream = streams.find(s => s.id === req.params.id);
  if (stream) { stream.active = false; }
  res.json({ message: "Ended", stream });
});

app.post('/streams/:id/record', auth, (req, res) => {
  const stream = streams.find(s => s.id === req.params.id);
  if (stream) { stream.recording = !stream.recording; }
  res.json({ message: "Recording toggled", stream });
});

// --- Stream Key CRUD ---
app.get('/admin/keys', auth, (req, res) => {
  res.json({ streamKeys: keys });
});

app.post('/admin/keys', auth, (req, res) => {
  const { key } = req.body;
  if (!key) return res.status(400).json({ message: "No key" });
  keys.push({ id: key, key });
  res.json({ message: "Key created", keys });
});

app.delete('/admin/keys/:id', auth, (req, res) => {
  keys = keys.filter(k => k.id !== req.params.id);
  res.json({ message: "Key deleted", keys });
});

// --- User Role Endpoint ---
app.get('/me', auth, (req, res) => {
  res.json({ username: req.user.username, role: req.user.role });
});

// --- Error Handling ---
app.use((err, req, res, next) => {
  res.status(500).json({ message: "Internal error", error: err.message });
});

app.listen(8080, () => console.log("Dashboard API running on :8080"));
EOF

cat > dashboard-backend/package.json <<'EOF'
{
  "name": "dashboard-backend",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.19.2",
    "cors": "^2.8.5",
    "jsonwebtoken": "^9.0.2"
  }
}
EOF

cat > dashboard-backend/Dockerfile <<'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
EXPOSE 8080
CMD ["node", "server.js"]
EOF

# --- NPM Installs ---
echo "Installing NPM dependencies for frontend..."
cd dashboard
npm install

echo "Installing NPM dependencies for backend..."
cd ../dashboard-backend
npm install

# --- DONE ---
echo
echo "Upgrade complete!"
echo "Frontend and backend files rewritten."
echo "To run locally:"
echo "  cd dashboard-backend && node server.js"
echo "  cd dashboard && npm start"
echo "Or use Docker Compose for both services."
echo
echo "Default login: Username 'admin', Password 'adminpass'"
