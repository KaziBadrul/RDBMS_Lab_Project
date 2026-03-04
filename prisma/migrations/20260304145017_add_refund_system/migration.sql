-- CreateEnum
CREATE TYPE "TicketStatus" AS ENUM ('booked', 'cancelled');

-- AlterTable
ALTER TABLE "Ticket" ADD COLUMN     "Status" "TicketStatus" NOT NULL DEFAULT 'booked';

-- CreateTable
CREATE TABLE "RefundTransaction" (
    "RefundID" SERIAL NOT NULL,
    "TicketID" INTEGER NOT NULL,
    "Amount" DECIMAL(8,2) NOT NULL,
    "RefundDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "Reason" VARCHAR(255),

    CONSTRAINT "RefundTransaction_pkey" PRIMARY KEY ("RefundID")
);

-- CreateIndex
CREATE UNIQUE INDEX "RefundTransaction_TicketID_key" ON "RefundTransaction"("TicketID");

-- AddForeignKey
ALTER TABLE "RefundTransaction" ADD CONSTRAINT "RefundTransaction_TicketID_fkey" FOREIGN KEY ("TicketID") REFERENCES "Ticket"("TicketID") ON DELETE CASCADE ON UPDATE CASCADE;

-- Create Procedure: cancel_ticket
CREATE OR REPLACE PROCEDURE cancel_ticket(
    p_ticket_id INT,
    p_cancelled_by INT,
    p_reason TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_trip_id INT;
    v_seat_number INT;
    v_price DECIMAL(8, 2);
    v_departure_time TIMESTAMP;
    v_hours_until_departure FLOAT;
    v_refund_amount DECIMAL(8, 2);
    v_status TEXT;
BEGIN
    -- 1. Fetch ticket and trip info
    SELECT t."TripID", t."SeatNumber", t."Price", tr."DepartureTime", t."Status"::TEXT
    INTO v_trip_id, v_seat_number, v_price, v_departure_time, v_status
    FROM "Ticket" t
    JOIN "Trip" tr ON t."TripID" = tr."TripID"
    WHERE t."TicketID" = p_ticket_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ticket % not found', p_ticket_id;
    END IF;

    IF v_status = 'cancelled' THEN
        RAISE EXCEPTION 'Ticket % is already cancelled', p_ticket_id;
    END IF;

    -- 2. Calculate hours until departure
    -- Using EXTRACT(EPOCH FROM ...) / 3600 to get hours
    v_hours_until_departure := EXTRACT(EPOCH FROM (v_departure_time - NOW())) / 3600;

    -- 3. Calculate refund amount based on policy
    -- > 24h: 100%
    -- 12h-24h: 75%
    -- < 12h: 50%
    IF v_hours_until_departure > 24 THEN
        v_refund_amount := v_price;
    ELSIF v_hours_until_departure >= 12 THEN
        v_refund_amount := v_price * 0.75;
    ELSE
        v_refund_amount := v_price * 0.50;
    END IF;

    -- 4. Update Ticket status to 'cancelled'
    UPDATE "Ticket"
    SET "Status" = 'cancelled'
    WHERE "TicketID" = p_ticket_id;

    -- 5. Release the seat
    UPDATE "Seat"
    SET "Status" = 'available'
    WHERE "TripID" = v_trip_id AND "SeatNumber" = v_seat_number;

    -- 6. Record Refund Transaction
    INSERT INTO "RefundTransaction" ("TicketID", "Amount", "Reason", "RefundDate")
    VALUES (p_ticket_id, v_refund_amount, p_reason, NOW());

    -- 7. Audit Log
    INSERT INTO "AuditLog" ("Action", "TableName", "RecordID", "UserID", "Details")
    VALUES (
        'CANCEL',
        'Ticket',
        p_ticket_id,
        p_cancelled_by,
        jsonb_build_object(
            'refund_amount', v_refund_amount,
            'reason', p_reason,
            'hours_before_departure', v_hours_until_departure
        )
    );

    RAISE NOTICE 'Ticket % cancelled. Refund amount: %', p_ticket_id, v_refund_amount;
END;
$$;
