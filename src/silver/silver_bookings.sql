-- Silver del hecho: limpieza, tipado, dedup y columnas derivadas como nights_stayed (noches de estadía)

-- valid_booking_id con FAIL UPDATE: una reserva con un id nulo es un error
-- valid_total_amount con DROP ROW: una reserva con monto ≤ 0 es un dato corrupto sin valor de negocio recuperable, no aporta nada a las métricas de revenue, mejor descartarla.
-- valid_dates sin ON VIOLATION (comportamiento warn): un check_out anterior o igual a check_in es raro pero no invalida completamente el registro 

CREATE OR REFRESH STREAMING TABLE silver_bookings_${student_name} (
  CONSTRAINT valid_booking_id EXPECT (booking_id IS NOT NULL) ON VIOLATION FAIL UPDATE,
  CONSTRAINT valid_total_amount EXPECT (total_amount > 0) ON VIOLATION DROP ROW,
  CONSTRAINT valid_dates EXPECT (check_out > check_in)
)
COMMENT 'Silver layer: bookings limpios, tipados y deduplicados'
AS
SELECT DISTINCT
  booking_id,
  user_id,
  property_id,
  CAST(check_in AS DATE) AS check_in,
  CAST(check_out AS DATE) AS check_out,
  guests_count,
  CAST(total_amount AS DECIMAL(10,2)) AS total_amount,
  LOWER(TRIM(status)) AS status,
  DATEDIFF(CAST(check_out AS DATE), CAST(check_in AS DATE)) AS nights_stayed,
  ROUND(CAST(total_amount AS DECIMAL(10,2)) / NULLIF(guests_count, 0), 2) AS price_per_guest
FROM STREAM(bronze_bookings_${student_name})
WHERE booking_id IS NOT NULL
  AND total_amount IS NOT NULL
  AND check_in IS NOT NULL
  AND check_out IS NOT NULL;

  