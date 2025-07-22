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
