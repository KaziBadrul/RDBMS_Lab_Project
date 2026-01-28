CREATE OR REPLACE FUNCTION get_trip_seats(p_trip_id integer)
RETURNS jsonb
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'seatNo', s."SeatNumber",
        'status', s."Status"::text
      )
      ORDER BY s."SeatNumber" ASC
    ),
    '[]'::jsonb
  )
  FROM "Seat" s
  WHERE s."TripID" = p_trip_id;
$$;

-- Usage:
-- SELECT get_trip_seats(123);