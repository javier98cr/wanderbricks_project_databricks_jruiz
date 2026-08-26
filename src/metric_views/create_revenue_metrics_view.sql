USE CATALOG IDENTIFIER(:catalog);
USE SCHEMA IDENTIFIER(:schema);

DECLARE OR REPLACE VARIABLE qry_str STRING;

SET VAR qry_str =
  "CREATE OR REPLACE VIEW revenue_metrics_" || :student_name || "
  (
    property_type COMMENT 'Tipo de propiedad',
    city COMMENT 'Ciudad donde está la propiedad',
    booking_month COMMENT 'Mes de la reserva',
    total_revenue COMMENT 'Ingreso total agregado',
    total_bookings COMMENT 'Cantidad total de reservas',
    avg_booking_value COMMENT 'Valor promedio por reserva',
    avg_revenue_per_night COMMENT 'Ingreso promedio por noche'
  )
  WITH METRICS
  LANGUAGE YAML
  AS $$
  version: 1.1

  source: " || :catalog || '.' || :schema || ".gold_revenue_by_property_" || :student_name || "

  dimensions:
    - name: property_type
      expr: property_type
      display_name: Property Type
    - name: city
      expr: city
      display_name: City
    - name: booking_month
      expr: booking_month
      display_name: Booking Month

  measures:
    - name: total_revenue
      expr: SUM(total_revenue)
      display_name: Total Revenue
    - name: total_bookings
      expr: SUM(total_bookings)
      display_name: Total Bookings
    - name: avg_booking_value
      expr: SUM(total_revenue) / SUM(total_bookings)
      display_name: Average Booking Value
    - name: avg_revenue_per_night
      expr: AVG(revenue_per_night)
      display_name: Average Revenue Per Night
  $$";

EXECUTE IMMEDIATE qry_str;