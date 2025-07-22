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
