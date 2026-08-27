
# Wanderbricks Pipeline Project
 
Pipeline gobernado con CI/CD sobre Databricks: arquitectura medallion (bronze, silver, gold), CDC sintético con SCD Type 2, capa semántica (Metric View), orquestación con Lakeflow Jobs, dashboard AI/BI y despliegue continuo con GitHub Actions y Databricks Asset Bundles.
 
## Arquitectura
 
```
Marketplace (Wanderbricks bookings)          CSV sintéticos (properties CDC)
        │                                              │
        ▼                                              ▼
  bronze_bookings                            bronze_properties (Auto Loader)
        │                                              │
        ▼                                              ▼
  silver_bookings                    silver_properties (AUTO CDC / SCD Type 2)
  (limpieza, tipado,                          │
   columnas derivadas)                        │
        └──────────────────┬───────────────────┘
                            ▼
              gold_revenue_by_property
                            │
                            ▼
                  revenue_metrics (Metric View)
                            │
                            ▼
                    Dashboard AI/BI
```
 
## Estructura del repositorio
 
```
├── databricks.yml              # Configuración raíz del bundle (targets: development, production)
├── resources/
│   ├── pipeline.yml            # Definición del pipeline SDP (bronze, silver, gold)
│   └── job.yml                 # Definición del Lakeflow Job (orquestación, lógica condicional)
├── src/
│   ├── bronze/                 # Ingesta de bookings (Marketplace) y properties (Auto Loader)
│   ├── silver/                 # Limpieza del hecho + AUTO CDC / SCD Type 2 de la dimensión
│   ├── gold/                   # Materialized View con las agregaciones de negocio
│   ├── metric_views/           # SQL task que despliega la Metric View vía EXECUTE IMMEDIATE
│   └── checks/                 # Notebook que valida el conteo de filas en Gold
└── data/
    └── properties_cdc/
        ├── batch1.csv           # Lote inicial de la dimensión properties
        └── batch2.csv           # Segundo lote: insert, update y delete
```
 
## Prerequisitos
 
- [Databricks CLI](https://docs.databricks.com/dev-tools/cli/install.html) instalado (`databricks --version` para confirmar).
- Autenticación configurada contra el workspace (perfil de CLI o variables de entorno `DATABRICKS_HOST` / `DATABRICKS_CLIENT_ID` / `DATABRICKS_CLIENT_SECRET`).
- Los siguientes objetos deben existir **antes** del primer deploy (no los crea el bundle):
```sql
-- Ambiente de desarrollo
CREATE CATALOG IF NOT EXISTS dab_jruiz_dev;
CREATE SCHEMA IF NOT EXISTS dab_jruiz_dev.wanderbricks_development;
CREATE VOLUME IF NOT EXISTS dab_jruiz_dev.wanderbricks_development.batches;
 
-- Ambiente de producción
CREATE CATALOG IF NOT EXISTS dab_jruiz_prod;
CREATE SCHEMA IF NOT EXISTS dab_jruiz_prod.wanderbricks_production;
CREATE VOLUME IF NOT EXISTS dab_jruiz_prod.wanderbricks_production.batches;
```
 
## Cargar los datos de CDC sintético
 
Antes de correr el pipeline por primera vez, sube el primer lote al Volume correspondiente:
 
```bash
databricks fs cp data/properties_cdc/batch1.csv \
  dbfs:/Volumes/dab_jruiz_dev/wanderbricks_development/batches/batch1.csv
```
 
Después de validar el estado inicial en `silver_properties` (historial SCD2 con una sola versión por propiedad), sube el segundo lote para probar el insert, el update y el delete:
 
```bash
databricks fs cp data/properties_cdc/batch2.csv \
  dbfs:/Volumes/dab_jruiz_dev/wanderbricks_development/batches/batch2.csv
```
 
Repite el mismo proceso apuntando a `dab_jruiz_prod` / `wanderbricks_production` cuando pruebes contra producción.
 
## Desplegar y correr el proyecto
 
### 1. Validar el bundle localmente
 
```bash
databricks bundle validate -t development
databricks bundle validate -t production
```
 
### 2. Desplegar a desarrollo
 
```bash
databricks bundle deploy -t development
```
 
Esto crea (o actualiza) el pipeline SDP y el Job en el workspace, dentro del catálogo `dab_jruiz_dev`.
 
### 3. Correr el Job
 
```bash
databricks bundle run Orchester_wanderbricks_project -t development
```
 
Esto ejecuta, en orden: el pipeline SDP (bronze → silver → gold), la creación/actualización de la Metric View, la validación del conteo de filas en Gold, y — si la validación pasa — el refresh del dashboard.
 
### 4. Repetir contra producción
 
```bash
databricks bundle deploy -t production
databricks bundle run Orchester_wanderbricks_project -t production
```
 
> En este proyecto, el despliegue a producción requiere aprobación de un revisor configurado en el Environment `prod` de GitHub — ver la sección de CI/CD más abajo.
 
## Flujo de CI/CD (GitHub Actions)
 
El proyecto usa dos branches (`dev` y `main`) y dos GitHub Environments (`dev` y `prod`), cada uno con sus propios secrets (`DATABRICKS_HOST`, `DATABRICKS_CLIENT_ID`, `DATABRICKS_CLIENT_SECRET`) correspondientes a un Service Principal distinto por ambiente.
 
- **Hacia `dev`:** un Pull Request dispara `databricks bundle validate -t development` como check obligatorio. Al hacer merge, un job separado corre `deploy` + `run` contra `dab_jruiz_dev`.
- **Hacia `main`:** un Pull Request desde `dev` dispara `databricks bundle validate -t production`, mismo Environment `prod` — por lo que incluso el validate requiere aprobación de un revisor. Al hacer merge, un segundo gate de aprobación protege el `deploy` + `run` contra `dab_jruiz_prod`.
Ver el diagrama de arquitectura en el documento de decisiones para el detalle visual de ambos flujos.
 
## Gobernanza (Unity Catalog)
 
Solo se otorga acceso de `SELECT` sobre la Metric View de producción (`revenue_metrics_jruiz`) y "Can Run" sobre el dashboard de producción al usuario docente — sin acceso a bronze, silver, al catálogo de desarrollo, ni al Job.
 
```sql
GRANT SELECT ON TABLE dab_jruiz_prod.wanderbricks_production.revenue_metrics_jruiz
TO `juan.morice@ulatina.net`;
```
 
## Notas
 
- Las tablas Silver son Streaming Tables: si se agrega una columna derivada nueva a una tabla ya existente, se requiere un **Full Refresh** de esa tabla específica para que la columna se calcule también sobre las filas históricas ya procesadas.
- El SQL Warehouse usado por los tasks de tipo `sql_task` (creación de la Metric View, conteo de filas en Gold) debe estar activo o con auto-start habilitado al momento de correr el Job.
 




Añadir comentario a este bloque