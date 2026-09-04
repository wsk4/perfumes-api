import express from 'express';
import { perfumes, getPerfumeById, createPerfume } from './perfumes.js';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'perfume-catalog-api' });
});

app.get('/perfumes', (req, res) => {
  const { category, sort } = req.query;
  let result = [...perfumes];

  
  if (category && category.trim() !== '') {
    result = result.filter(p => p.category === category);
  }

  if (search && search.trim() !== '') {
    result = result.filter(p => 
      p.name.toLowerCase().includes(search.toLowerCase())
    );
  }

  
  if (sort === 'price_asc') {
    result.sort((a, b) => a.price - b.price);
  } else if (sort === 'price_desc') {
    result.sort((a, b) => b.price - a.price);
  }

  res.json(result);
});

app.get('/perfumes/:id', (req, res) => {
    const perfume = getPerfumeById(Number(req.params.id));
    if (!perfume) return res.status(404).json({ error: 'Perfume not found' });
    res.json(perfume);
});

app.post('/perfumes', (req, res) => {
    const { name, brand, price, category, stock } = req.body;
    if (!name || !brand || !price || !category) {
        return res.status(400).json({ error: 'Missing required fields' });
    }
    if (price <= 0 || stock < 0) {
        return res.status(400).json({ error: 'Invalid price or stock' });
    }
    const newPerfume = createPerfume({ name, brand, price, category, stock });
    res.status(201).json(newPerfume);
});

app.listen(PORT, () => {
    console.log(`Perfume Catalog API running on port ${PORT}`);
});