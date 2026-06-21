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

INSERT INTO public.bonus VALUES ('1b2febd8-d8a4-4b67-ba65-e287a1815532', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'Toefl Tinggi', '', 1000000, '2026-06-22', '2026-06-21 10:01:50.872493-07', '2026-06-21 10:01:50.872493-07');


--
-- Data for Name: companies; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.companies VALUES ('b1c7a24d-c446-4bb2-bc9b-d19cb70c5fb6', 'Astra', 'Balige', 'astra@gmail.com', '0881080811110', '', 0, 0, 'ACTIVE', '2026-06-13 00:41:38.201761-07');
INSERT INTO public.companies VALUES ('SYSTEM', 'System Administration', 'System', 'videntiiii@gmail.com', '000', '', 0, 0, 'ACTIVE', '2026-06-13 00:22:37.024942-07');
INSERT INTO public.companies VALUES ('eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'Astra International', 'Balige', 'astra@gmail.com', '0881080811110', '', 0, 0, 'ACTIVE', '2026-06-13 03:44:02.627152-07');


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.notifications VALUES ('0c13a56b-ee96-490e-bccb-9456d742c160', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'Bonus Baru!', 'Anda menerima bonus sebesar Rp 1.000.000 untuk: Toefl Tinggi', 'BONUS_RECEIVED', '1b2febd8-d8a4-4b67-ba65-e287a1815532', false, '2026-06-21 10:01:50.921398-07');


--
-- Data for Name: penalties; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: positions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.positions VALUES ('1e332dec-14d9-4516-923a-63f99c95fc71', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'Owner', 0, '', '2026-06-13 03:44:02.629662-07', '2026-06-21 10:58:34.640221-07');
INSERT INTO public.positions VALUES ('bc8c7e38-0e7e-4304-a1f2-307a95ce0a03', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'HRD', 1000000000, 'qwdsdasdsdf', '2026-06-13 03:56:49.33749-07', '2026-06-21 10:58:34.729173-07');
INSERT INTO public.positions VALUES ('774acf97-2208-4ebf-8f6b-20ad635ea902', 'b1c7a24d-c446-4bb2-bc9b-d19cb70c5fb6', 'Owner', 0, '', '2026-06-13 00:41:38.20277-07', '2026-06-13 03:21:46.424237-07');
INSERT INTO public.positions VALUES ('421c7ecc-38da-4e9e-b919-e771b3d2f0c5', 'b1c7a24d-c446-4bb2-bc9b-d19cb70c5fb6', 'HRD', 10000000, 'Ini tugasnya manipulasi kerjaan', '2026-06-13 01:03:55.680663-07', '2026-06-13 03:21:46.487094-07');


--
-- Data for Name: salaries; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.salaries VALUES ('691bbb28-bf02-49a7-a6a0-3f4725aec854', '07458220-573e-4bff-a07e-407c8c6f2d5e', 6, 2026, 1000000000, 5390000, 1000000, 995610000, 0, '2026-06-03: Rp25000; 2026-06-05: Rp25000; 2026-06-11: Rp25000; 2026-06-12: Rp15000; 2026-06-15: Rp300000; 2026-06-15: Lupa Check-out (Rp1000000); 2026-06-16: Alpha (Rp1000000); 2026-06-17: Alpha (Rp1000000); 2026-06-18: Alpha (Rp1000000); 2026-06-19: Alpha (Rp1000000)', '2026-06-22: Toefl Tinggi (Rp1000000)', 'PENDING', '', NULL, '2026-06-13 03:56:33.877538-07', '2026-06-21 10:39:53.478283-07');
INSERT INTO public.salaries VALUES ('af41b61d-75cb-4c66-a4ea-1ed8d4d45135', '07458220-573e-4bff-a07e-407c8c6f2d5e', 5, 2026, 1000000000, 1205000, 0, 998795000, 0, '2026-05-01: Rp25000; 2026-05-07: Rp25000; 2026-05-08: Rp25000; 2026-05-14: Rp15000; 2026-05-20: Rp25000; 2026-05-25: Rp25000; 2026-05-26: Rp25000; 2026-05-27: Rp25000; 2026-05-29: Rp15000; 2026-05-04: Alpha (Rp1000000)', '', 'PENDING', '', NULL, '2026-06-13 08:06:59.938386-07', '2026-06-21 10:39:53.489493-07');


--
-- Data for Name: salary_payments; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users VALUES ('SUPER-ADMIN-ID', 'SYSTEM', NULL, 'Super Admin', 'videntiiii@gmail.com', '$2a$14$ebxi7hb4pmi4SMYxWJYv1OJEwPuha8se7TznYlM1vS5aMVUn3I.qO', '', '', '', '', '', '', '', 'SUPER_ADMIN', 'ACTIVE', '', '', '', '', '', NULL, 0, NULL, '2026-06-13 00:22:37.879184-07', '2026-06-21 10:58:34.868285-07');
INSERT INTO public.users VALUES ('859f8da5-0ea0-4ed7-84b8-557878c134a2', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '1e332dec-14d9-4516-923a-63f99c95fc71', 'Oktova Samosir', 'oktovaaaaa@gmail.com', '$2a$14$wYr8ipdaKhBN3lsqF/49wuaUiu3H4EjGloVpKNVmT076tMkoVmEqO', '$2a$10$jLexoAqU2V6iFYHBMIO4EezKnj5ErEeHtfHhxzLIsFtycj6jffOAW', '0881080811110', 'Kediri', '2000-01-18', 'Balige', '', '', 'ADMIN', 'ACTIVE', '', '', '', '', '', NULL, 0, NULL, '2026-06-13 03:44:02.63067-07', '2026-06-21 10:58:35.067259-07');
INSERT INTO public.users VALUES ('07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'bc8c7e38-0e7e-4304-a1f2-307a95ce0a03', 'Okoltova', 'okoltova@gmail.com', '$2a$14$xIm.I1pNft.SAI2XcE9lveNo9/JUFmQs1/TUkmsLcPYwP1D6zhFKK', '$2a$10$ZOh407xDkgeh6JWJWy.oEO2ojGaRO649.ASZx9aeOTCR9Rj/R38RC', '0881080811110', 'Balige', '2000-01-12', 'Balige', '', 'eOLJ0yBYRuOf2lYVersw2y:APA91bHW3onmGIeJw4IglWAphZIShTfX_7LvDSMKt2zvD_dpRSdmGtmlwaMkmwKqg5-RUIYocyiHwl872z1iw2mWzVFczsoPK2O9BZHj6sD3Sx-MennZQ1I', 'EMPLOYEE', 'ACTIVE', '', '1782061193997', 'Mandiri', '100110001', '[1.1207719,0.9126593,1.2098266,-0.5668856,-0.2703379,1.4556952,-0.8032554,-0.7509675,0.55196893,-0.21761677,0.18949585,0.15935937,-0.45563316,-0.21215408,-1.3440886,0.30266988,0.9202639,-0.22201088,0.9508314,-0.9438478,0.09134332,-2.2290332,0.8756779,0.9357548,-0.013222599,-0.9103936,-1.1052251,-0.700463,0.42169148,0.40565044,1.8049746,-0.3981052,-0.766935,-1.5567287,-0.06201334,-0.95096904,-0.16840644,0.59943324,-0.6247894,-1.3917499,0.48170575,-0.6453255,1.4200736,-0.0054976763,-0.94202363,0.91495407,0.5585769,0.9199332,0.017591571,0.45933628,2.0891356,0.77290255,0.2565899,0.749807,0.6541742,0.4061165,-0.5102259,-0.18873963,0.44966635,0.27033454,-0.020135213,0.70517564,0.3405925,0.70220524,0.88630646,-0.56560117,0.11216004,-0.845821,-0.5722488,-0.21965234,-1.1087811,-1.2639225,-0.06359477,-1.8693348,-2.312765,0.80740374,-0.6907581,-2.398169,2.870074,-0.1940062,-0.12495799,-1.234894,-0.03684609,0.4819758,-0.8168621,-0.30520028,0.16687915,-0.5321039,0.18061946,0.49307427,0.15783384,0.71388024,0.45478305,0.17604223,-0.3515219,1.235952,0.26846778,-0.9163332,-0.12697008,-0.14771947,0.6701703,0.118246555,0.29231542,0.45930535,0.24063635,0.12826692,-1.5397105,-1.8761089,-0.8695749,0.5943904,1.3084223,1.0048763,0.6483868,-0.8402544,-1.1792262,0.64597917,0.43342,-1.1993501,-0.925553,0.48678845,-0.80755126,0.50608796,-0.1887699,0.3033433,-0.19914007,0.6224171,-0.10708181,-0.7643081,0.3435232,1.1700939,2.2670949,0.37064153,-0.28491428,-0.42688957,-1.2782873,0.28478855,0.46919656,0.14542592,0.82071173,0.64823085,0.48666304,-0.3972944,-0.94275886,-1.3591901,-1.4004638,0.8162648,-0.30664793,0.25948432,0.4125704,0.7890534,-0.8761773,0.24367857,0.50243443,1.3057083,1.2643979,-0.48816624,-0.5771948,-2.308709,-0.14931624,1.0799654,0.9606632,0.82229596,-0.679313,0.11738219,0.5053931,1.3435733,-1.0791147,-1.0596172,-1.5984211,0.33363724,0.18401003,-1.5648706,0.20362219,1.8019425,0.9110284,0.8437298,-0.004124701,1.6549441,1.6650465,0.7419015,1.3880078,0.9398674,-0.8937828,0.071731515,-0.8357962,-0.58242875,0.17729104,-1.3263547,1.4275258,-0.8971488,-0.4447183,-0.05535195,1.8602422,0.7209047,-1.3553793,-1.7037399,-1.4680068,0.23481917,1.1956613,-0.3638088,0.40342623,-0.7441036,1.4806433,-0.87387514,2.6068337,0.82799846,1.2179253,-0.50465715,0.27389964,0.6254822,-1.673205,0.018896744,-0.42619458,-1.0674084,0.36609903,1.3061584,-0.3333846,-0.38010627,-1.5098455,0.70861024,2.5012517,1.2956057,-0.3657624,0.17413525,-0.56966174,-0.8689806,-1.3279027,-0.66187054,0.45246476,-0.7175317,-0.8627998,-1.279258,0.74225193,0.26343316,-1.2351115,-0.67269677,-2.267681,1.4140738,-1.3886913,-0.021134805,-0.004731131,-1.5963554,-1.1232865,-0.43035278,2.2516625,1.2590996,-0.06233375,-0.27593857,-0.9419466,-0.19287567,-0.10155477,0.4404307,0.3510055,0.20640893,1.006051,-1.0255171,-1.3715498,0.28879485,1.3032961,2.0152586,-0.47571453,-1.2232931,0.20138197,-0.41438237,0.9296352,-0.3620651,-0.22629333,0.370885,0.685338,-1.3865938,0.7968562,-0.34255573,0.55731755,0.563043,0.14021268,0.21942797,-0.50390816,0.5430641,2.150064,-0.14005224,-0.97987354,0.693881,0.68151253,-0.36511058,1.363597,-0.1902726,-0.5741547,-1.3980142,1.1508468,-0.6039119,0.9023787,0.458277,1.2562693,1.4327614,0.13872722,-0.87681836,-0.7074223,-0.640958,0.022049237,0.27018338,-0.4700424,-0.41286126,-0.73764884,2.0408008,0.30284867,0.5003173,-1.2449881,0.47049767,0.13998121,-0.2567188,0.41325435,0.3990062,-0.006187141,1.6621351,1.3808619,1.1087517,0.9795079,0.5854128,-0.15125644,-1.3111045,0.30463266,-3.1919866,-0.48630685,0.89397156,-1.1012194,0.70835525,-1.1495605,1.7949129,-0.66446555,0.2530052,-0.38633654,-1.2763433,-1.3831159,0.50690985,-0.55842817,0.113633774,-1.1969467,-0.8436182,0.4286674,1.222512,-0.563401,0.8129814,0.2814424,-1.7584345,-1.4905945,0.37057418,0.15519209,0.22425826,0.34624362,0.5307883,1.9075896,0.42349362,0.206392,-0.8894488,-0.94267815,-0.28119397,0.22779736,-0.40643635,0.36162603,-0.8104828,0.18994626,0.28215498,-0.86789787,0.052875064,0.580851,-0.9897763,0.3401986,-0.15573342,0.9103001,-0.38408,1.3754326,2.3464646,-1.231678,-1.2709213,0.6193847,0.48222333,-1.075134,0.012198359,0.42217198,-0.06779256,-1.4329469,-0.14978547,0.3833211,0.8609268,0.3146364,0.56150776,1.0764219,0.2514854,0.64610165,-0.8343561,-0.69405764,-0.7854825,0.17289396,0.72246045,0.5527665,1.6913815,-0.036836654,0.76910555,-0.88319033,-0.30991608,-0.45129877,-1.7076114,-0.11216613,0.44434348,-1.5158947,1.2583282,-0.6692414,0.5582768,-0.76357585,-0.13612981,-0.48821408,0.13026932,0.9371213,-1.1860845,0.89594316,0.33763522,0.5716299,-0.597984,0.33494806,-1.4116724,-0.22322007,0.5538207,-0.2792618,0.4198249,0.020191956,0.41294178,-1.011089,0.8225583,-0.88504916,0.8486352,-0.5665962,1.7815044,1.0800383,0.4473589,0.051748075,-0.9939704,-0.39654255,-0.12166347,-0.20743462,0.36696282,0.31313452,-0.41386333,-1.3152449,-0.5863405,-0.07797481,-1.0488069,0.07362262,0.25074813,1.0901706,0.5947198,-0.19010147,-0.79862744,-1.5502746,1.3697847,0.7271026,0.1411514,0.15721083,-2.7996423,-1.2956475,-0.23840931,-0.17198293,0.2373311,-0.6570356,0.9913052,1.3107898,0.94384634,-1.1432683,-0.32035705,-0.79981184,-0.9310873,0.16035691,-0.16875106,-0.64528114,0.82677066,-0.66442466,-1.2934912,2.1232784,-0.8219944,0.07957338,0.71331877,0.6134652,-0.86438835,1.1867185,0.23348503,-1.3878989,-0.16704121,0.93600166,2.1281419,2.0673325,-0.6085377,-0.6513777,-0.7100093,-1.2485359,0.6998446,-0.2604607,0.060066245,0.34634328,-0.38704178,0.51476747,1.0236061,-1.6058375,0.7604754,1.6348966,-0.07772335,-1.6561638,-0.6502997,0.5433016,-0.45344788,-0.7162412,0.12050954,0.46627226,0.22326283]', NULL, 0, NULL, '2026-02-28 09:00:00-08', '2026-06-21 10:58:35.136553-07');


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

