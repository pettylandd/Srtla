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
