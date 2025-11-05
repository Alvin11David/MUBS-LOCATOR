const express = require('express');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();

const app = express();
app.use(cors());               // allow any origin
app.use(express.json());

const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;   // hide key

app.get('/directions', async (req, res) => {
  const { origin, destination } = req.query;
  if (!origin || !destination) return res.status(400).json({ error: 'missing params' });

  const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${origin}&destination=${destination}&mode=walking&key=${GOOGLE_API_KEY}`;

  try {
    const { data } = await axios.get(url);
    res.json(data);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => console.log(`Proxy listening on ${PORT}`));