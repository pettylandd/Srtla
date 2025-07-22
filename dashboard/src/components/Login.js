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
