const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('API funcionando 👍');
});

app.get('/api/launcher/news', (req, res) => {
  res.json([
    {
      id: 1,
      title: "Launcher online",
      description: "Tudo funcionando",
      image: "https://via.placeholder.com/300",
      date: "2026-04-14"
    }
  ]);
});

app.get('/api/launcher/donate', (req, res) => {
  res.json([
    { id: 1, title: "VIP", price: 10 }
  ]);
});

app.get('/distribution.json', (req, res) => {
  res.json({
    version: "1.0.0",
    required: true
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log("Rodando na porta " + PORT));
