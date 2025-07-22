import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

// Pass the API URL as a prop to App
const apiUrl = process.env.REACT_APP_SRTLA_API || "http://localhost:8080";

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App apiUrl={apiUrl} />);
