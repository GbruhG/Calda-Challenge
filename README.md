## Testing the edge function

The seeded users can't sign in (inserted directly into auth.users). Create a user first:
```bash
curl -X POST "http://localhost:54321/auth/v1/signup" \
  -H "apikey: ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@test.com", "password": "password123", "data": {"first_name": "Test", "last_name": "User"}}'
```

Get a JWT:
```bash
curl -X POST "http://localhost:54321/auth/v1/token?grant_type=password" \
  -H "apikey: ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@test.com", "password": "password123"}'
```

Call the function:
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

## Testing the CRON job

The job runs daily at midnight. To trigger it manually:
```sql
update public.orders set created_at = now() - interval '8 days' where id = '20000000-0000-0000-0000-000000000001';
select public.archive_and_delete_old_orders();
```