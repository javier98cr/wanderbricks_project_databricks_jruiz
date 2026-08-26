CREATE OR REFRESH MATERIALIZED VIEW gold_revenue_by_property_${student_name}
COMMENT 'Ingreso agregado por tipo de propiedad y ciudad, usando la versión vigente de properties (SCD2)'
AS
SELECT
  p.property_type,
  p.city,
  DATE_TRUNC('month', b.check_in) AS booking_month,
  COUNT(b.booking_id) AS total_bookings,
  SUM(b.total_amount) AS total_revenue,
  ROUND(AVG(b.total_amount), 2) AS avg_booking_value,
  ROUND(SUM(b.total_amount) / SUM(b.nights_stayed), 2) AS revenue_per_night
FROM silver_bookings_${student_name} b
JOIN silver_properties_${student_name} p
  ON b.property_id = p.property_id
WHERE p.__END_AT IS NULL
GROUP BY p.property_type, p.city, DATE_TRUNC('month', b.check_in);