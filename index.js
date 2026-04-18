const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();

function readJson(fileName) {
  const filePath = path.join(__dirname, fileName);
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

app.get('/', (_, res) => {
  res.send('API funcionando 👍');
});

app.get('/distribution.json', (_, res) => {
  res.json(readJson('distribution.json'));
});

app.get('/api/launcher/news', (_, res) => {
  res.json(readJson('news.json'));
});

app.get('/api/launcher/donate', (_, res) => {
  res.json(readJson('donate.json'));
});

app.use('/mobile', express.static(path.join(__dirname, 'mobile')));
app.use('/image', express.static(path.join(__dirname, 'image')));
app.use('/storage', express.static(path.join(__dirname, 'storage')));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Rodando na porta ${PORT}`));
