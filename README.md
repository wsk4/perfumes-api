# 🎯 Perfume Catalog API

API de catálogo de perfumes desarrollada con Node.js + Express.

## 🌿 Estrategia de ramificación (IE1)

Se utiliza **GitFlow** porque permite separar claramente desarrollo, integración y producción, facilitando la colaboración en equipos amplios. Este modelo es ideal para proyectos con releases planificados y mantenimiento paralelo de versiones.

### Ramas utilizadas
- `main` → producción estable.
- `develop` → integración continua.
- `feature/*` → nuevas funcionalidades.
- `hotfix/*` → correcciones urgentes a producción.

### Comparación con otros modelos

| Modelo | Ventajas | Desventajas | Cuándo usar |
|--------|----------|-------------|-------------|
| **GitFlow** | Control estricto, separación clara entre dev/prod | Más complejo, más ramas | Proyectos con releases planificados |
| **Trunk-Based** | Velocidad, simplicidad, CI/CD nativo | Requiere feature flags, madurez en testing | Equipos ágiles con deployments frecuentes |

**Justificación:** GitFlow fue seleccionado porque este proyecto académico requiere demostrar dominio de ramas feature, develop, main y hotfix, con releases controlados y trazabilidad clara, además el equipo considero que era el mejor metodo para el trabajo.

## ⚙️ GitHub Actions (IE3, IE4)

El workflow `.github/workflows/ci.yml` se ejecuta automáticamente en:
- **Push a `develop`**: Integra cambios continuamente.
- **Pull Request a `main`**: Valida antes de mergear a producción.

### Pasos del workflow

1. **Checkout**: Obtiene el código del repositorio.
2. **Setup Node.js**: Configura entorno Node.js 20.
3. **Setup pnpm**: Instala pnpm para gestión eficiente de dependencias.
4. **Install dependencies**: Instala dependencias con `pnpm install --frozen-lockfile`.
5. **Run linter**: Valida calidad del código con ESLint.
6. **Run tests**: Ejecuta pruebas unitarias con Jest.

### Rol en CI/CD

Este workflow automatiza la **Integración Continua (CI)**, asegurando que:
- Todo el código es testeado antes de integrarse.
- Los errores se detectan temprano (shift-left testing).
- Solo código validado llega a producción.

**Beneficios:**
- Reduce errores en producción.
- Acelera el feedback a desarrolladores.
- Documenta el estado del build en cada commit.

## 📋 Guía de buenas prácticas (IE5)

### Naming de ramas

| Tipo | Patrón | Ejemplo |
|------|--------|---------|
| Producción | `main` | `main` |
| Integración | `develop` | `develop` |
| Feature | `feature/<descripcion>` | `feature/agregar-filtro-categoria` |
| Hotfix | `hotfix/<descripcion>` | `hotfix/fix validacion` |

### Mensajes de commit (Conventional Commits)

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| `feat:` | Nueva funcionalidad | `feat:agregar busqueda por nombre` |
| `fix:` | Corrección de bug | `fix: validar que el id del perfume sea numerico` |
| `test:` | Pruebas unitarias | `test: agregar pruebas unitarias para modulo de perfumes` |
| `ci:` | Configuración CI/CD | `ci: agregar workflows con pnpm para push en develop y pr en main` |
| `docs:` | Documentación | `docs:agregar README` |

### Estructura de carpetas

perfume-catalog-api/

├── .github/workflows/ → GitHub Actions (ci.yml) 

├── src/ → Código fuente (index.js, perfumes.js)

├── tests/ → Pruebas unitarias (perfumes.test.js)

├── package.json → Dependencias y scripts

├── pnpm-lock.yaml → Lockfile de pnpm

└── README.md → Documentación del proyecto


### Control de versiones

- **Commits pequeños y frecuentes**: Cada commit debe tener un propósito claro.
- **PRs con descripción**: Todo PR debe explicar qué cambia y por qué.
- **Revisión de código obligatoria**: Al menos 1 approval antes de mergear.
- **Tests deben pasar**: GitHub Actions debe estar en verde antes de mergear.

## 🔄 Trazabilidad de cambios (IE2)

| Fecha | Rama | Tipo | Commit | Descripción | PR |
|-------|------|------|--------|-------------|-----|
| 2026-09-03 | feature/agregar-filtro-categoria | feat | 150fd0f | Agregar filtro por categoría | #3 |
| 2026-09-03 | feature/pruebas-unitarias | test | 8fe066b | Agregar pruebas unitarias | #2 |
| 2026-09-03 | feature/configuracion-ci | ci | 603b472 | Configurar GitHub Actions | #1 |
| 2026-09-03 | feature-busqueda-por-nombre | feat | b723c9e | Agregar búsqueda por nombre | #4 |
| 2026-09-04 | develop → main | release | 2ad014f | Release v1.0.0 | #5 |
| 2026-09-04 | hotfix/fix-validacion-id | fix | 69898d6 | Validar formato de ID | #6 |
| 2026-09-04 | main → develop | sync | 993f755 | Sincronizar hotfix | #7 |

## 🚀 Instalación y uso

```bash
# Clonar repositorio
git clone https://github.com/wsk4/perfumes-api.git

# Instalar dependencias
pnpm install

# Ejecutar en desarrollo
pnpm dev

# Ejecutar tests
pnpm test

# Ejecutar en producción
pnpm start
```

## 📦 Endpoints

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/health` | Salud del servicio |
| GET | `/perfumes` | Lista todos los perfumes |
| GET | `/perfumes/:id` | Obtiene un perfume por ID |
| POST | `/perfumes` | Crea un nuevo perfume |

### Query params para GET /perfumes

| Param | Descripción | Ejemplo |
|-------|-------------|---------|
| `category` | Filtrar por categoría | `?category=femenino` |
| `search` | Buscar por nombre | `?search=chanel` |
| `sort` | Ordenar por precio | `?sort=price_asc` |

### Ejemplos de uso

```bash
# Listar todos los perfumes
GET /perfumes

# Filtrar por categoría
GET /perfumes?category=femenino

# Buscar por nombre
GET /perfumes?search=chanel

# Ordenar por precio ascendente
GET /perfumes?sort=price_asc

# Combinar filtros
GET /perfumes?category=femenino&search=chanel&sort=price_asc
```

## 👥 Equipo

| Integrante | GitHub | Responsabilidades |
|------------|--------|-------------------|
| Matias Gonzalez V| @wsk4|CI/CD, GitHub Actions y feature: busqueda por nombre|
| Renato Barriga P| @Moonlighpoio|Feature: filtro por categoría|
| Cristobal Veliz L| @Veliz1232|Tests, CI/CD y hotfix|

## 📄 Licencia

Proyecto académico para evaluación de GitFlow y DevOps.

## USO IA

Se utilizo AI para crear el microservicio de manera básica, mejorar el léxico de los commits junto algunas descripciones, resolver bugs(errores que desconocíamos), la estructuración y algunos pasos del README.
Por ultimo se utilizo para corroborar el cumplimiento de la pauta de evaluación y como consultor.
