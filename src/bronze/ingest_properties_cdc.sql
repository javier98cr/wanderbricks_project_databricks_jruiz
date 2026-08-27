-- Bronze: ingesta incremental de los archivos CDC sintéticos de properties
CREATE OR REFRESH STREAMING TABLE bronze_properties_${student_name}
COMMENT 'Bronze layer: Raw properties CDC data'
AS SELECT *,
    current_timestamp() AS processing_time,
    _metadata.file_name AS source_file
FROM STREAM read_files(
  '/Volumes/${catalog}/${schema}/batches',
  format => 'csv',
  header => 'true'
);