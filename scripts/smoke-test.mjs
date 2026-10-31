#!/usr/bin/env node
/**
 * Smoke test del despliegue. Se ejecuta contra el gateway (Nginx) del
 * entorno levantado con Docker Compose. El gateway no se expone a una URL
 * configurable para que esta verificación nunca ejecute solicitudes arbitrarias.
 */
const assert = (condition, message) => {
  if (!condition) {
    throw new Error(`ASSERT FAILED: ${message}`);
  }
};

const parseJson = async (res, expectedStatus, path) => {
  const body = await res.json().catch(() => null);
  assert(res.status === expectedStatus, `${path} -> ${res.status} (esperado ${expectedStatus})`);
  return { res, body };
};

const main = async () => {
  // Espera activa: Compose puede tardar en levantar las réplicas.
  let healthy = false;
  for (let attempt = 1; attempt <= 30 && !healthy; attempt += 1) {
    try {
      const res = await fetch('http://localhost:3000/health', { signal: AbortSignal.timeout(3000) });
      healthy = res.ok;
    } catch {
      healthy = false;
    }
    if (!healthy) await new Promise((resolve) => setTimeout(resolve, 2000));
  }
  assert(healthy, 'el servicio no respondió en http://localhost:3000/health');

  const health = await parseJson(await fetch('http://localhost:3000/health'), 200, '/health');
  assert(health.body.status === 'ok', 'health.status debe ser ok');
  console.log('OK  GET /health');

  const all = await parseJson(await fetch('http://localhost:3000/perfumes'), 200, '/perfumes');
  assert(Array.isArray(all.body) && all.body.length > 0, 'el catálogo debe ser un arreglo no vacío');
  console.log('OK  GET /perfumes');

  const filtered = await parseJson(await fetch('http://localhost:3000/perfumes?category=masculino'), 200, '/perfumes?category=masculino');
  assert(filtered.body.every((p) => p.category === 'masculino'), 'el filtro por categoría no se aplicó');
  console.log('OK  GET /perfumes?category=masculino');

  const searched = await parseJson(await fetch('http://localhost:3000/perfumes?search=dior'), 200, '/perfumes?search=dior');
  assert(searched.body.some((p) => p.name.toLowerCase().includes('dior')), 'la búsqueda por nombre no devolvió resultados');
  console.log('OK  GET /perfumes?search=dior');

  const sorted = await parseJson(await fetch('http://localhost:3000/perfumes?sort=price_asc'), 200, '/perfumes?sort=price_asc');
  const prices = sorted.body.map((p) => p.price);
  assert(JSON.stringify(prices) === JSON.stringify([...prices].sort((a, b) => a - b)), 'el orden ascendente no es correcto');
  console.log('OK  GET /perfumes?sort=price_asc');

  const byId = await parseJson(await fetch('http://localhost:3000/perfumes/1'), 200, '/perfumes/1');
  assert(byId.body.id === 1, 'GET /perfumes/1 no devolvió el perfume esperado');
  console.log('OK  GET /perfumes/1');

  const invalid = await parseJson(await fetch('http://localhost:3000/perfumes/abc'), 400, '/perfumes/abc');
  assert(invalid.body.error === 'Invalid ID format', 'el ID inválido no devolvió 400');
  console.log('OK  GET /perfumes/abc -> 400');

  await parseJson(await fetch('http://localhost:3000/perfumes/99999'), 404, '/perfumes/99999');
  console.log('OK  GET /perfumes/99999 -> 404');

  const missing = await parseJson(await fetch('http://localhost:3000/no-existe'), 404, '/no-existe');
  assert(missing.body.error === 'Not found', 'la ruta desconocida no devolvió 404');
  console.log('OK  GET /no-existe -> 404');

  const created = await fetch('http://localhost:3000/perfumes', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: 'Perfume Smoke Test',
      brand: 'Equipo EP2',
      price: 19990,
      category: 'unisex',
      stock: 3
    }),
    signal: AbortSignal.timeout(10000)
  });
  assert(created.status === 201, `POST /perfumes -> ${created.status} (esperado 201)`);
  const createdBody = await created.json();
  assert(createdBody.id, 'el perfume creado no tiene id');
  console.log('OK  POST /perfumes -> 201');

  const response = await fetch('http://localhost:3000/health');
  assert(response.headers.get('x-content-type-options') === 'nosniff', 'faltan cabeceras de seguridad del gateway');
  console.log('OK  cabeceras de seguridad del gateway');

  console.log('\nSmoke test completado correctamente.');
};

main().catch((error) => {
  console.error(`\nSmoke test falló: ${error.message}`);
  process.exit(1);
});
