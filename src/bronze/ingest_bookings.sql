-- Bronze: ingesta del hecho principal desde el Marketplace (CDF habilitado en el share)
CREATE OR REFRESH STREAMING TABLE bronze_bookings_${student_name}
COMMENT 'Bronze layer: Raw bookings data from wanderbricks dataset'
AS SELECT *,
  current_timestamp() AS processing_time,
  _metadata.file_name AS source_file
FROM STREAM(databricks_wanderbricks_dataset_dais_2025.wanderbricks.bookings);