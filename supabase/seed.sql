insert into auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_user_meta_data,
  created_at,
  updated_at
) values
  (
    '00000000-0000-0000-0000-000000000001',
    'you@youremail.com',
    crypt('password123', gen_salt('bf')),
    now(),
    '{"first_name": "Ana", "last_name": "Novak"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'you+1@youremail.com',
    crypt('password123', gen_salt('bf')),
    now(),
    '{"first_name": "Luka", "last_name": "Horvat"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    'you+2@youremail.com',
    crypt('password123', gen_salt('bf')),
    now(),
    '{"first_name": "Maja", "last_name": "Kovač"}',
    now(),
    now()
  );


-- prices in cents (4999 = €49.99)
insert into public.items (id, name, price, stock) values
  ('10000000-0000-0000-0000-000000000001', 'Wireless Headphones', 4999,  50),
  ('10000000-0000-0000-0000-000000000002', 'Phone Case',          1499, 100),
  ('10000000-0000-0000-0000-000000000003', 'USB-C Cable',          999, 200),
  ('10000000-0000-0000-0000-000000000004', 'Laptop Stand',        3499,  30),
  ('10000000-0000-0000-0000-000000000005', 'Mechanical Keyboard', 8999,  15);


insert into public.orders (id, user_id, recipient_name, shipping_address) values
  (
    '20000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'Ana Novak',
    'Slovenska cesta 1, 1000 Ljubljana, Slovenia'
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000001',
    'Ana Novak',
    'Slovenska cesta 1, 1000 Ljubljana, Slovenia'
  ),
  (
    '20000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000002',
    'Luka Horvat',
    'Cankarjeva ulica 5, 2000 Maribor, Slovenia'
  );


-- order 1 (ana): headphones x1 + usb-c cable x2
insert into public.order_items (order_id, item_id, quantity, unit_price) values
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 1, 4999),
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000003', 2,  999);

-- order 2 (ana): laptop stand x1 + keyboard x1 + phone case x1
insert into public.order_items (order_id, item_id, quantity, unit_price) values
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000004', 1, 3499),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000005', 1, 8999),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 1, 1499);

-- order 3 (luka): phone case x3 + usb-c cable x1
insert into public.order_items (order_id, item_id, quantity, unit_price) values
  ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000002', 3, 1499),
  ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', 1,  999);