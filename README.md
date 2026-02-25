## Testing the edge functions

The seeded users can't sign in (inserted directly into auth.users). Create a user and get access token:
```bash
curl -X POST "http://localhost:54321/auth/v1/signup" \
  -H "apikey: ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@test.com", "password": "password123", "data": {"first_name": "Test", "last_name": "User"}}'
```

**create-order** creates a new order, checks stock, reduces stock on success:
```bash
curl -X POST http://localhost:54321/functions/v1/create-order \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "recipient_name": "Test User",
    "shipping_address": "Slovenska cesta 1, Ljubljana",
    "items": [
      { "item_id": "10000000-0000-0000-0000-000000000001", "quantity": 1 },
      { "item_id": "10000000-0000-0000-0000-000000000002", "quantity": 2 }
    ]
  }'
```

**get-orders** returns all orders for the current user. Pass `order_id` to get a single order:
```bash
curl http://localhost:54321/functions/v1/get-orders \
  -H "Authorization: Bearer ACCESS_TOKEN"

curl "http://localhost:54321/functions/v1/get-orders?order_id=ORDER_UUID" \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

**update-order** updates order status. Valid order status flow: `pending -> confirmed -> shipped -> delivered`. Can only cancel from `pending` or `confirmed`:
```bash
curl -X PATCH http://localhost:54321/functions/v1/update-order \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"order_id": "ORDER_UUID", "status": "confirmed"}'
```

## Testing the CRON job

Job runs daily at midnight. To trigger it manually:
```sql
update public.orders set created_at = now() - interval '8 days' where id = 'ORDER_UUID';
select public.archive_and_delete_old_orders();
```