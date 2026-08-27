
-- Silver de la dimensión: historial SCD Type 2 vía AUTO CDC

--valid_property_id: una propiedad con id nulo es invalido y deberia generar un error
--valid_price con DROP ROW: mismo razonamiento que total_amount — un precio negativo o cero rompe cualquier cálculo de revenue downstream.
--valid_property_type sin ON VIOLATION (warn): puedes seguir contando la propiedad en el histórico y en el revenue total aunque no puedas agruparla por tipo — no justifica perder la fila completa.

CREATE OR REFRESH STREAMING TABLE silver_properties_${student_name} (
  CONSTRAINT valid_property_id EXPECT (property_id IS NOT NULL) ON VIOLATION FAIL UPDATE,
  CONSTRAINT valid_price EXPECT (base_price > 0) ON VIOLATION DROP ROW,
  CONSTRAINT valid_property_type EXPECT (property_type IS NOT NULL)
)
COMMENT 'Silver layer: historial SCD Type 2 de properties';

CREATE FLOW scd_type_2_properties_${student_name} AS
AUTO CDC INTO silver_properties_${student_name}
FROM STREAM bronze_properties_${student_name}
    KEYS (property_id)
    APPLY AS DELETE WHEN operation = 'DELETE'
    SEQUENCE BY to_timestamp(timestamp, 'yyyy-MM-dd HH:mm:ss')
    COLUMNS * EXCEPT (operation, timestamp, _rescued_data, processing_time, source_file)
    STORED AS SCD TYPE 2;