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
