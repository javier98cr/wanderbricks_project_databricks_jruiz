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
  DATEDIFF(CAST(check_out AS DATE), CAST(check_in AS DATE)) AS nights_stayed
FROM STREAM(bronze_bookings_${student_name})
WHERE booking_id IS NOT NULL
  AND total_amount IS NOT NULL
  AND check_in IS NOT NULL
  AND check_out IS NOT NULL;