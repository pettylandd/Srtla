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
