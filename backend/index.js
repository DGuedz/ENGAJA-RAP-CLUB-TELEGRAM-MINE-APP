import express from 'express';
const app = express();
app.get('/', (_req, res) => res.send('OK'));
app.listen(3001, () => console.log('Backend listening on 3001'));
