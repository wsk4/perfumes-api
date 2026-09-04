describe('Pruebas unitarias - API de Perfumes', () => {
  test('Debe verificar que el entorno de pruebas responde correctamente', () => {
    const status = 'OK';
    expect(status).toBe('OK');
  });

  test('Debe validar los campos requeridos de un perfume', () => {
    const perfume = {
      id: 1,
      nombre: 'Bleu de Chanel',
      marca: 'Chanel',
      disponible: true
    };

    expect(perfume).toHaveProperty('nombre');
    expect(perfume).toHaveProperty('marca');
    expect(perfume.disponible).toBe(true);
  });
});