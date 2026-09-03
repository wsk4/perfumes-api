let perfumes = [
    { id: 1, name: 'Chanel No. 5', brand: 'Chanel', price: 129990, category: 'femenino', stock: 15 },
    { id: 2, name: 'Dior Sauvage', brand: 'Dior', price: 99990, category: 'masculino', stock: 20 }
];

let nextId = 3;

export { perfumes };

export function getPerfumeById(id) {
    return perfumes.find(p => p.id === id);
}

export function createPerfume({ name, brand, price, category, stock }) {
    const newPerfume = { id: nextId++, name, brand, price, category, stock: stock || 0 };
    perfumes.push(newPerfume);
    return newPerfume;
}