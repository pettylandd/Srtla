#!/bin/bash

set -e

# Create dashboard folders
mkdir -p dashboard/public
mkdir -p dashboard/src/components

# --- Dockerfile ---
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

# --- package.json ---
cat > dashboard/package.json <<'EOF'
{
  "name": "srtla-dashboard",
  "version": "1.0.0",
  "main": "src/index.js",
  "dependencies": {
    "react": "^18.3.0",
    "react-dom": "^18.3.0",
    "axios": "^1.6.0",
    "@mui/material": "^5.15.0",
    "@mui/icons-material": "^5.15.0",
    "react-scripts": "^5.0.1"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build"
  }
}
EOF

# --- public/index.html ---
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

# --- src/index.js ---
cat > dashboard/src/index.js <<'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);
EOF

# --- src/App.js ---
cat > dashboard/src/App.js <<'EOF'
import React, { useState } from 'react';
import { CssBaseline, Container, Paper, Typography } from '@mui/material';
import Login from './components/Login';
import Dashboard from './components/Dashboard';

function App() {
  const [token, setToken] = useState(null);

  return (
    <CssBaseline>
      <Container maxWidth="md">
        <Paper elevation={3} sx={{ marginTop: 4, padding: 3 }}>
          <Typography variant="h3" align="center" sx={{ mb: 3 }}>SRTLA Receiver Dashboard</Typography>
          {!token ? <Login setToken={setToken} /> : <Dashboard token={token} setToken={setToken} />}
        </Paper>
      </Container>
    </CssBaseline>
  );
}

export default App;
EOF

# --- src/components/Login.js ---
cat > dashboard/src/components/Login.js <<'EOF'
import React, { useState } from 'react';
import { TextField, Button, Alert, Box } from '@mui/material';

export default function Login({ setToken }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    // Replace this with your authentication API if you have one!
    if (username === 'admin' && password === 'adminpass') {
      setToken('demo-token');
    } else {
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

# --- src/components/Dashboard.js ---
cat > dashboard/src/components/Dashboard.js <<'EOF'
import React from 'react';
import StreamList from './StreamList';
import AdminPanel from './AdminPanel';
import { Button, Box } from '@mui/material';

export default function Dashboard({ token, setToken }) {
  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      <Button variant="outlined" sx={{ alignSelf: 'flex-end' }} onClick={() => setToken(null)}>Logout</Button>
      <StreamList token={token} />
      <AdminPanel token={token} />
    </Box>
  );
}
EOF

# --- src/components/StreamList.js ---
cat > dashboard/src/components/StreamList.js <<'EOF'
import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { Card, CardMedia, CardContent, Typography, Grid, Chip, Stack } from '@mui/material';
import StreamControls from './StreamControls';

const API_BASE = process.env.REACT_APP_SRTLA_API || "http://receiver:8080";

export default function StreamList({ token }) {
  const [streams, setStreams] = useState([]);

  useEffect(() => {
    axios.get(`${API_BASE}/streams`)
      .then(res => setStreams(res.data));
  }, []);

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

# --- src/components/StreamControls.js ---
cat > dashboard/src/components/StreamControls.js <<'EOF'
import React, { useState } from 'react';
import { Button, Stack, Snackbar } from '@mui/material';
import axios from 'axios';

const API_BASE = process.env.REACT_APP_SRTLA_API || "http://receiver:8080";

export default function StreamControls({ stream, token }) {
  const [snackbar, setSnackbar] = useState({ open: false, message: '' });

  const handleRecord = async () => {
    // Replace with your actual record API endpoint!
    const res = await axios.post(`${API_BASE}/streams/${stream.id}/record`);
    setSnackbar({ open: true, message: res.data.message || 'Recording toggled.' });
  };

  return (
    <>
      <Stack direction="row" spacing={2}>
        <Button variant="contained" onClick={handleRecord}>Toggle Record</Button>
        {/* Add more controls here, e.g. Publish/Restream */}
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

# --- src/components/AdminPanel.js ---
cat > dashboard/src/components/AdminPanel.js <<'EOF'
import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { Card, CardContent, Typography, Button, Chip, Stack } from '@mui/material';

const API_BASE = process.env.REACT_APP_SRTLA_API || "http://receiver:8080";

export default function AdminPanel({ token }) {
  const [keys, setKeys] = useState([]);
  const [resetMsg, setResetMsg] = useState('');

  useEffect(() => {
    axios.get(`${API_BASE}/admin/keys`)
      .then(res => setKeys(res.data.streamKeys || []));
  }, []);

  const resetSystem = async () => {
    const res = await axios.post(`${API_BASE}/admin/reset`);
    setResetMsg(res.data.message || 'System reset');
    setTimeout(() => setResetMsg(''), 2000);
  };

  return (
    <Card sx={{ mt: 4 }}>
      <CardContent>
        <Typography variant="h6">Admin Panel</Typography>
        <Typography>Stream Keys:</Typography>
        <Stack direction="row" spacing={1} sx={{ my: 1 }}>
          {keys.map(k => <Chip key={k} label={k} color="primary" />)}
        </Stack>
        <Button variant="contained" color="warning" onClick={resetSystem}>Reset System</Button>
        {resetMsg && <Typography color="success.main" sx={{ mt: 1 }}>{resetMsg}</Typography>}
      </CardContent>
    </Card>
  );
}
EOF
