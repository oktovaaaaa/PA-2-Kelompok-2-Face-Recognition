--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS fk_users_position;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS fk_users_company;
ALTER TABLE IF EXISTS ONLY public.salaries DROP CONSTRAINT IF EXISTS fk_salaries_user;
ALTER TABLE IF EXISTS ONLY public.salary_payments DROP CONSTRAINT IF EXISTS fk_salaries_payments;
ALTER TABLE IF EXISTS ONLY public.positions DROP CONSTRAINT IF EXISTS fk_positions_company;
ALTER TABLE IF EXISTS ONLY public.penalties DROP CONSTRAINT IF EXISTS fk_penalties_user;
ALTER TABLE IF EXISTS ONLY public.notifications DROP CONSTRAINT IF EXISTS fk_notifications_user;
ALTER TABLE IF EXISTS ONLY public.notifications DROP CONSTRAINT IF EXISTS fk_notifications_company;
ALTER TABLE IF EXISTS ONLY public.bonus DROP CONSTRAINT IF EXISTS fk_bonus_user;
DROP INDEX IF EXISTS public.idx_user_month_year;
DROP INDEX IF EXISTS public.idx_salary_payments_salary_id;
DROP INDEX IF EXISTS public.idx_positions_company_id;
DROP INDEX IF EXISTS public.idx_penalties_user_id;
DROP INDEX IF EXISTS public.idx_notifications_user_id;
DROP INDEX IF EXISTS public.idx_notifications_company_id;
DROP INDEX IF EXISTS public.idx_bonus_user_id;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS uni_users_email;
ALTER TABLE IF EXISTS ONLY public.salary_payments DROP CONSTRAINT IF EXISTS salary_payments_pkey;
ALTER TABLE IF EXISTS ONLY public.salaries DROP CONSTRAINT IF EXISTS salaries_pkey;
ALTER TABLE IF EXISTS ONLY public.positions DROP CONSTRAINT IF EXISTS positions_pkey;
ALTER TABLE IF EXISTS ONLY public.penalties DROP CONSTRAINT IF EXISTS penalties_pkey;
ALTER TABLE IF EXISTS ONLY public.notifications DROP CONSTRAINT IF EXISTS notifications_pkey;
ALTER TABLE IF EXISTS ONLY public.companies DROP CONSTRAINT IF EXISTS companies_pkey;
ALTER TABLE IF EXISTS ONLY public.bonus DROP CONSTRAINT IF EXISTS bonus_pkey;
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.salary_payments;
DROP TABLE IF EXISTS public.salaries;
DROP TABLE IF EXISTS public.positions;
DROP TABLE IF EXISTS public.penalties;
DROP TABLE IF EXISTS public.notifications;
DROP TABLE IF EXISTS public.companies;
DROP TABLE IF EXISTS public.bonus;
SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bonus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bonus (
    id text NOT NULL,
    user_id text,
    title text,
    description text,
    amount numeric,
    date text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.bonus OWNER TO postgres;

--
-- Name: companies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.companies (
    id text NOT NULL,
    name text,
    address text,
    email text,
    phone text,
    logo_url text,
    latitude numeric,
    longitude numeric,
    status text DEFAULT 'ACTIVE'::text,
    created_at timestamp with time zone
);


ALTER TABLE public.companies OWNER TO postgres;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id text NOT NULL,
    user_id text,
    company_id text,
    title text,
    body text,
    type text,
    ref_id text,
    is_read boolean,
    created_at timestamp with time zone
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: penalties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.penalties (
    id text NOT NULL,
    user_id text,
    type text,
    title text,
    description text,
    amount numeric,
    attachment text,
    date text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.penalties OWNER TO postgres;

--
-- Name: positions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.positions (
    id text NOT NULL,
    company_id text,
    name text,
    salary numeric,
    description text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.positions OWNER TO postgres;

--
-- Name: salaries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.salaries (
    id text NOT NULL,
    user_id text,
    month bigint,
    year bigint,
    base_salary numeric,
    deductions numeric,
    bonuses numeric,
    total_salary numeric,
    paid_amount numeric,
    deductions_detail text,
    bonuses_detail text,
    status text,
    payment_proof text,
    paid_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.salaries OWNER TO postgres;

--
-- Name: salary_payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.salary_payments (
    id text NOT NULL,
    salary_id text,
    amount numeric,
    proof text,
    paid_at timestamp with time zone,
    created_at timestamp with time zone
);


ALTER TABLE public.salary_payments OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id text NOT NULL,
    company_id text,
    position_id text,
    name text,
    email text,
    password text,
    pin text,
    phone text,
    birth_place text,
    birth_date text,
    address text,
    photo_url text,
    fcm_token text,
    role text,
    status text,
    google_id text,
    device_id text,
    bank_name text,
    bank_account_number text,
    face_embedding text,
    face_updated_at timestamp with time zone,
    invalid_pin_attempts bigint,
    pin_locked_until timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Data for Name: bonus; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bonus (id, user_id, title, description, amount, date, created_at, updated_at) FROM stdin;
1b2febd8-d8a4-4b67-ba65-e287a1815532	07458220-573e-4bff-a07e-407c8c6f2d5e	Toefl Tinggi		1000000	2026-06-22	2026-06-21 10:01:50.872493-07	2026-06-21 10:01:50.872493-07
\.


--
-- Data for Name: companies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.companies (id, name, address, email, phone, logo_url, latitude, longitude, status, created_at) FROM stdin;
b1c7a24d-c446-4bb2-bc9b-d19cb70c5fb6	Astra	Balige	astra@gmail.com	0881080811110		0	0	ACTIVE	2026-06-13 00:41:38.201761-07
SYSTEM	System Administration	System	videntiiii@gmail.com	000		0	0	ACTIVE	2026-06-13 00:22:37.024942-07
eaa1123a-b7fe-42e4-a94a-bafc55eaef95	Astra International	Balige	astra@gmail.com	0881080811110		0	0	ACTIVE	2026-06-13 03:44:02.627152-07
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, user_id, company_id, title, body, type, ref_id, is_read, created_at) FROM stdin;
0c13a56b-ee96-490e-bccb-9456d742c160	07458220-573e-4bff-a07e-407c8c6f2d5e	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	Bonus Baru!	Anda menerima bonus sebesar Rp 1.000.000 untuk: Toefl Tinggi	BONUS_RECEIVED	1b2febd8-d8a4-4b67-ba65-e287a1815532	f	2026-06-21 10:01:50.921398-07
\.


--
-- Data for Name: penalties; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.penalties (id, user_id, type, title, description, amount, attachment, date, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: positions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.positions (id, company_id, name, salary, description, created_at, updated_at) FROM stdin;
774acf97-2208-4ebf-8f6b-20ad635ea902	b1c7a24d-c446-4bb2-bc9b-d19cb70c5fb6	Owner	0		2026-06-13 00:41:38.20277-07	2026-06-13 03:21:46.424237-07
421c7ecc-38da-4e9e-b919-e771b3d2f0c5	b1c7a24d-c446-4bb2-bc9b-d19cb70c5fb6	HRD	10000000	Ini tugasnya manipulasi kerjaan	2026-06-13 01:03:55.680663-07	2026-06-13 03:21:46.487094-07
1e332dec-14d9-4516-923a-63f99c95fc71	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	Owner	0		2026-06-13 03:44:02.629662-07	2026-11-19 17:27:38.062042-08
bc8c7e38-0e7e-4304-a1f2-307a95ce0a03	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	HRD & Personalia	8500000	Mengelola administrasi dan SDM	2026-06-13 03:56:49.33749-07	2026-11-19 17:27:38.194561-08
pos-staff-it	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	Software Engineer	8000000	Pengembangan sistem dan aplikasi	2026-11-19 18:19:56.087091-08	2026-11-19 18:19:56.087091-08
pos-staff-frontend	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	Frontend Developer	7500000	Pengembangan antarmuka web dan mobile	2026-11-19 18:19:56.094643-08	2026-11-19 18:19:56.094643-08
pos-staff-finance	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	Finance & Accounting	6500000	Pengelolaan keuangan dan penggajian	2026-11-19 18:19:56.09513-08	2026-11-19 18:19:56.09513-08
pos-staff-marketing	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	Digital Marketing	6000000	Pemasaran digital dan komunikasi	2026-11-19 18:19:56.095573-08	2026-11-19 18:19:56.095573-08
pos-staff-ops	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	Operational Support	5500000	Dukungan operasional kantor	2026-11-19 18:19:56.096027-08	2026-11-19 18:19:56.096027-08
\.


--
-- Data for Name: salaries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.salaries (id, user_id, month, year, base_salary, deductions, bonuses, total_salary, paid_amount, deductions_detail, bonuses_detail, status, payment_proof, paid_at, created_at, updated_at) FROM stdin;
691bbb28-bf02-49a7-a6a0-3f4725aec854	07458220-573e-4bff-a07e-407c8c6f2d5e	6	2026	1000000000	5390000	1000000	995610000	0	2026-06-03: Rp25000; 2026-06-05: Rp25000; 2026-06-11: Rp25000; 2026-06-12: Rp15000; 2026-06-15: Rp300000; 2026-06-15: Lupa Check-out (Rp1000000); 2026-06-16: Alpha (Rp1000000); 2026-06-17: Alpha (Rp1000000); 2026-06-18: Alpha (Rp1000000); 2026-06-19: Alpha (Rp1000000)	2026-06-22: Toefl Tinggi (Rp1000000)	PENDING		\N	2026-06-13 03:56:33.877538-07	2026-06-21 10:39:53.478283-07
af41b61d-75cb-4c66-a4ea-1ed8d4d45135	07458220-573e-4bff-a07e-407c8c6f2d5e	5	2026	1000000000	1205000	0	998795000	0	2026-05-01: Rp25000; 2026-05-07: Rp25000; 2026-05-08: Rp25000; 2026-05-14: Rp15000; 2026-05-20: Rp25000; 2026-05-25: Rp25000; 2026-05-26: Rp25000; 2026-05-27: Rp25000; 2026-05-29: Rp15000; 2026-05-04: Alpha (Rp1000000)		PENDING		\N	2026-06-13 08:06:59.938386-07	2026-06-21 10:39:53.489493-07
13e4c61a-9bed-46c0-9f46-dba8e4d982d6	07458220-573e-4bff-a07e-407c8c6f2d5e	11	2026	8500000	0	0	8500000	0			PENDING		\N	2026-11-19 18:14:26.904438-08	2026-11-19 18:21:11.828718-08
60ba3e07-6b66-4650-9869-150c7d9aa852	emp-002-budi	11	2026	8000000	350000	0	7650000	0	2026-11-13: Rp100000; 2026-11-04: Rp50000; 2026-11-06: Rp100000; 2026-11-10: Rp100000		PENDING		\N	2026-11-19 18:21:11.839748-08	2026-11-19 18:21:11.839162-08
feec3cbc-032c-4d36-8a28-b5281b9a8c64	emp-003-siti	11	2026	6500000	200000	0	6300000	0	2026-11-03: Rp50000; 2026-11-12: Rp100000; 2026-11-17: Rp50000		PENDING		\N	2026-11-19 18:21:11.850108-08	2026-11-19 18:21:11.84943-08
4ae65525-58a1-44cc-88d1-2d957efe4ff5	emp-004-ahmad	11	2026	7500000	0	0	7500000	0			PENDING		\N	2026-11-19 18:21:11.859265-08	2026-11-19 18:21:11.858722-08
c6257b26-9ca3-4c59-887e-bd5f1dc23eb6	emp-005-dewi	11	2026	6000000	100000	0	5900000	0	2026-11-12: Rp100000		PENDING		\N	2026-11-19 18:21:11.869409-08	2026-11-19 18:21:11.868879-08
7dc8f429-631e-4807-b3e4-498e8fe7b734	emp-006-rian	11	2026	5500000	250000	0	5250000	0	2026-11-03: Rp100000; 2026-11-17: Rp100000; 2026-11-19: Rp50000		PENDING		\N	2026-11-19 18:21:11.877513-08	2026-11-19 18:21:11.876953-08
\.


--
-- Data for Name: salary_payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.salary_payments (id, salary_id, amount, proof, paid_at, created_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, company_id, position_id, name, email, password, pin, phone, birth_place, birth_date, address, photo_url, fcm_token, role, status, google_id, device_id, bank_name, bank_account_number, face_embedding, face_updated_at, invalid_pin_attempts, pin_locked_until, created_at, updated_at) FROM stdin;
SUPER-ADMIN-ID	SYSTEM	\N	Super Admin	videntiiii@gmail.com									SUPER_ADMIN	ACTIVE						\N	0	\N	2026-06-13 00:22:37.879184-07	2026-11-19 17:27:38.294596-08
admin-pifor-id-001	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	1e332dec-14d9-4516-923a-63f99c95fc71	Admin Pifor	piforrr@gmail.com			081234567890	Jakarta	1995-01-01	Kantor Pusat			ADMIN	ACTIVE			BCA	enc:urt6JVqUPtzpj318pA1tLXMEubAUZVjq01YG4CNChs3msIatigU=		\N	0	\N	2026-11-19 17:23:08.105163-08	2026-11-19 17:27:38.63862-08
07458220-573e-4bff-a07e-407c8c6f2d5e	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	bc8c7e38-0e7e-4304-a1f2-307a95ce0a03	Okoltova	okoltova@gmail.com	$2a$14$wvtz8MWBQnntQOk9v0vXLOcwAz3l5aNpqIYLgvRwMLtL3xvk2oo7G	$2a$10$jLexoAqU2V6iFYHBMIO4EezKnj5ErEeHtfHhxzLIsFtycj6jffOAW	0881080811110	Balige	2000-01-12	Balige			EMPLOYEE	ACTIVE			Mandiri	enc:Nqn/qWNyxuXgzavpS2oPgQbvuLC7h944IecB5pkfwT+oDE9Z0g==		\N	0	\N	2026-02-28 09:00:00-08	2026-11-19 17:27:38.495575-08
emp-002-budi	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	pos-staff-it	Budi Santoso	budi.santoso@gmail.com	$2a$14$wvtz8MWBQnntQOk9v0vXLOcwAz3l5aNpqIYLgvRwMLtL3xvk2oo7G	$2a$10$jLexoAqU2V6iFYHBMIO4EezKnj5ErEeHtfHhxzLIsFtycj6jffOAW	081234567801	Medan	1998-05-10	Balige, Toba			EMPLOYEE	ACTIVE			BCA	8820192831		\N	0	\N	2026-07-31 18:00:00-07	2026-11-19 18:19:56.097162-08
emp-003-siti	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	pos-staff-finance	Siti Rahma	siti.rahma@gmail.com	$2a$14$wvtz8MWBQnntQOk9v0vXLOcwAz3l5aNpqIYLgvRwMLtL3xvk2oo7G	$2a$10$jLexoAqU2V6iFYHBMIO4EezKnj5ErEeHtfHhxzLIsFtycj6jffOAW	081234567802	Medan	1998-05-10	Balige, Toba			EMPLOYEE	ACTIVE			BRI	0192830192831		\N	0	\N	2026-07-31 18:00:00-07	2026-11-19 18:19:56.098709-08
emp-004-ahmad	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	pos-staff-frontend	Ahmad Fauzi	ahmad.fauzi@gmail.com	$2a$14$wvtz8MWBQnntQOk9v0vXLOcwAz3l5aNpqIYLgvRwMLtL3xvk2oo7G	$2a$10$jLexoAqU2V6iFYHBMIO4EezKnj5ErEeHtfHhxzLIsFtycj6jffOAW	081234567803	Medan	1998-05-10	Balige, Toba			EMPLOYEE	ACTIVE			BNI	9812039182		\N	0	\N	2026-07-31 18:00:00-07	2026-11-19 18:19:56.099305-08
emp-005-dewi	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	pos-staff-marketing	Dewi Lestari	dewi.lestari@gmail.com	$2a$14$wvtz8MWBQnntQOk9v0vXLOcwAz3l5aNpqIYLgvRwMLtL3xvk2oo7G	$2a$10$jLexoAqU2V6iFYHBMIO4EezKnj5ErEeHtfHhxzLIsFtycj6jffOAW	081234567804	Medan	1998-05-10	Balige, Toba			EMPLOYEE	ACTIVE			BSI	7182910293		\N	0	\N	2026-07-31 18:00:00-07	2026-11-19 18:19:56.099772-08
emp-006-rian	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	pos-staff-ops	Rian Pratama	rian.pratama@gmail.com	$2a$14$wvtz8MWBQnntQOk9v0vXLOcwAz3l5aNpqIYLgvRwMLtL3xvk2oo7G	$2a$10$jLexoAqU2V6iFYHBMIO4EezKnj5ErEeHtfHhxzLIsFtycj6jffOAW	081234567805	Medan	1998-05-10	Balige, Toba			EMPLOYEE	ACTIVE			CIMB Niaga	800192837192		\N	0	\N	2026-07-31 18:00:00-07	2026-11-19 18:19:56.100236-08
859f8da5-0ea0-4ed7-84b8-557878c134a2	eaa1123a-b7fe-42e4-a94a-bafc55eaef95	1e332dec-14d9-4516-923a-63f99c95fc71	Oktova Samosir	oktovaaaaa@gmail.com			0881080811110	Kediri	2000-01-18	Balige			ADMIN	ACTIVE						\N	0	\N	2026-06-13 03:44:02.63067-07	2026-11-19 18:21:12.581396-08
\.


--
-- Name: bonus bonus_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bonus
    ADD CONSTRAINT bonus_pkey PRIMARY KEY (id);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: penalties penalties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.penalties
    ADD CONSTRAINT penalties_pkey PRIMARY KEY (id);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (id);


--
-- Name: salaries salaries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salaries
    ADD CONSTRAINT salaries_pkey PRIMARY KEY (id);


--
-- Name: salary_payments salary_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_payments
    ADD CONSTRAINT salary_payments_pkey PRIMARY KEY (id);


--
-- Name: users uni_users_email; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uni_users_email UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_bonus_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bonus_user_id ON public.bonus USING btree (user_id);


--
-- Name: idx_notifications_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_company_id ON public.notifications USING btree (company_id);


--
-- Name: idx_notifications_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: idx_penalties_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_penalties_user_id ON public.penalties USING btree (user_id);


--
-- Name: idx_positions_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_positions_company_id ON public.positions USING btree (company_id);


--
-- Name: idx_salary_payments_salary_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_salary_payments_salary_id ON public.salary_payments USING btree (salary_id);


--
-- Name: idx_user_month_year; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_user_month_year ON public.salaries USING btree (user_id, month, year);


--
-- Name: bonus fk_bonus_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bonus
    ADD CONSTRAINT fk_bonus_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: notifications fk_notifications_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_notifications_company FOREIGN KEY (company_id) REFERENCES public.companies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: notifications fk_notifications_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: penalties fk_penalties_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.penalties
    ADD CONSTRAINT fk_penalties_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: positions fk_positions_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT fk_positions_company FOREIGN KEY (company_id) REFERENCES public.companies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: salary_payments fk_salaries_payments; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salary_payments
    ADD CONSTRAINT fk_salaries_payments FOREIGN KEY (salary_id) REFERENCES public.salaries(id);


--
-- Name: salaries fk_salaries_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.salaries
    ADD CONSTRAINT fk_salaries_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: users fk_users_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_company FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: users fk_users_position; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_position FOREIGN KEY (position_id) REFERENCES public.positions(id);


--
-- PostgreSQL database dump complete
--

