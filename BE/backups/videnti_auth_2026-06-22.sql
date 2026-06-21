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
-- Name: company_locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.company_locations (
    id text NOT NULL,
    company_id text,
    name text,
    latitude numeric,
    longitude numeric,
    radius numeric,
    is_active boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.company_locations OWNER TO postgres;

--
-- Name: invite_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invite_tokens (
    id text NOT NULL,
    token text,
    company_id text,
    status text,
    expires_at timestamp with time zone,
    created_at timestamp with time zone
);


ALTER TABLE public.invite_tokens OWNER TO postgres;

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
-- Name: otps; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.otps (
    id text NOT NULL,
    email text,
    code text,
    type text,
    used boolean,
    expires_at timestamp with time zone,
    created_at timestamp with time zone
);


ALTER TABLE public.otps OWNER TO postgres;

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
-- Name: sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sessions (
    id text NOT NULL,
    user_id text,
    token text,
    device_id text,
    device_name text,
    is_locked boolean,
    last_active_at timestamp with time zone,
    expires_at timestamp with time zone,
    created_at timestamp with time zone
);


ALTER TABLE public.sessions OWNER TO postgres;

--
-- Name: testimonials; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.testimonials (
    id bigint NOT NULL,
    user_id text,
    name text NOT NULL,
    rating bigint NOT NULL,
    description text NOT NULL,
    photo_url text,
    is_approved boolean DEFAULT false,
    created_at timestamp with time zone
);


ALTER TABLE public.testimonials OWNER TO postgres;

--
-- Name: testimonials_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.testimonials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.testimonials_id_seq OWNER TO postgres;

--
-- Name: testimonials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.testimonials_id_seq OWNED BY public.testimonials.id;


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
-- Name: testimonials id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testimonials ALTER COLUMN id SET DEFAULT nextval('public.testimonials_id_seq'::regclass);


--
-- Data for Name: companies; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.companies VALUES ('SYSTEM', 'System Administration', 'System', 'videntiiii@gmail.com', '000', '', 0, 0, 'ACTIVE', '2026-06-13 00:22:37.024942-07');
INSERT INTO public.companies VALUES ('eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'Astra International', 'Balige', 'astra@gmail.com', '0881080811110', '', 0, 0, 'ACTIVE', '2026-06-13 03:44:02.627152-07');


--
-- Data for Name: company_locations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: invite_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.invite_tokens VALUES ('dc04cc84-9b9b-4a34-bf2c-16c454598615', '91675bb1-868b-4428-bf84-1fac822f6200', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'USED', '2026-06-13 06:45:03.319874-07', '2026-06-13 03:45:03.320415-07');
INSERT INTO public.invite_tokens VALUES ('f334e81d-f954-4281-9d1e-c5ff99c2269c', '1e67f620-05f7-4146-9e21-c7dad50946d7', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'UNUSED', '2026-06-16 22:05:52.638716-07', '2026-06-16 19:05:52.638716-07');
INSERT INTO public.invite_tokens VALUES ('8ade555f-fd26-4ce7-abdc-b217957c3bdd', 'e8bea44d-de86-4e7b-a38c-67234f428326', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'UNUSED', '2026-06-16 23:34:49.208191-07', '2026-06-16 20:34:49.208191-07');


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.notifications VALUES ('d5a99999-fdfb-4a7c-a382-2287327ffd8a', '859f8da5-0ea0-4ed7-84b8-557878c134a2', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'Pendaftaran Karyawan Baru', 'Okoltova telah mendaftar dan sedang menunggu persetujuan Anda.', 'EMPLOYEE_REGISTERED', '07458220-573e-4bff-a07e-407c8c6f2d5e', false, '2026-06-13 03:47:40.424367-07');
INSERT INTO public.notifications VALUES ('f2c4b176-9538-4836-acb3-37e58a2a34e0', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'Akun Disetujui', 'Selamat! Akun Anda telah disetujui oleh Bos. Anda sekarang dapat mengakses seluruh fitur aplikasi.', 'EMPLOYEE_APPROVED', '07458220-573e-4bff-a07e-407c8c6f2d5e', false, '2026-06-13 03:47:49.117062-07');
INSERT INTO public.notifications VALUES ('8e420d59-36b7-4142-9864-aa70565e47a2', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'Perubahan Jabatan', 'Posisi jabatan Anda telah diperbarui menjadi HRD.', 'POSITION_UPDATE', 'bc8c7e38-0e7e-4304-a1f2-307a95ce0a03', false, '2026-06-13 03:57:22.967993-07');
INSERT INTO public.notifications VALUES ('519f6ed4-552c-44bf-9d45-417c27a9ec8e', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'Bonus Baru!', 'Anda menerima bonus sebesar Rp 1.000.000 untuk: Toefl Tinggi', 'BONUS_RECEIVED', '1b2febd8-d8a4-4b67-ba65-e287a1815532', false, '2026-06-21 10:01:50.923679-07');


--
-- Data for Name: otps; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.otps VALUES ('c635b6a0-8450-4984-96a6-d3d6fc8a3f2b', 'oktovaaaaa@gmail.com', '354694', '', true, '2026-06-13 00:45:18.252929-07', '2026-06-13 00:40:18.252929-07');
INSERT INTO public.otps VALUES ('3c6e5a6d-9f66-4587-911b-c4507c2bf592', 'oktovaaaaa@gmail.com', '539205', 'LOGIN', true, '2026-06-13 00:49:22.307267-07', '2026-06-13 00:44:22.307267-07');
INSERT INTO public.otps VALUES ('5d8af50e-7e3e-47c4-b92d-1c18cafb4c3c', 'videntiiii@gmail.com', '729183', '', true, '2026-06-13 00:55:30.738124-07', '2026-06-13 00:50:30.738124-07');
INSERT INTO public.otps VALUES ('12bd55ea-23de-4e04-8f55-b5416617bb07', 'oktovaaaaa@gmail.com', '529766', '', true, '2026-06-13 00:57:27.71436-07', '2026-06-13 00:52:27.71436-07');
INSERT INTO public.otps VALUES ('be54dfb9-ba3c-4be9-a9bc-2391921a5b2b', 'osvaldind04@gmail.com', '475032', '', true, '2026-06-13 01:00:59.409919-07', '2026-06-13 00:55:59.409919-07');
INSERT INTO public.otps VALUES ('cab71af1-f3e2-45c7-8d5a-3d97ecc6c723', 'osvaldind04@gmail.com', '450369', 'LOGIN', true, '2026-06-13 01:14:02.40546-07', '2026-06-13 01:09:02.40546-07');
INSERT INTO public.otps VALUES ('3ffe9a50-299c-4527-9797-598f75cd0d4f', 'osvaldind04@gmail.com', '098151', 'LOGIN', true, '2026-06-13 02:12:11.611839-07', '2026-06-13 02:07:11.612838-07');
INSERT INTO public.otps VALUES ('8c7b7abc-788b-4689-99a3-a16f3859afff', 'oktovaaaaa@gmail.com', '363835', '', true, '2026-06-13 03:46:52.603249-07', '2026-06-13 03:41:52.603249-07');
INSERT INTO public.otps VALUES ('5047df5a-d672-4117-a013-d3deb0de8c30', 'oktovaaaaa@gmail.com', '120368', '', true, '2026-06-13 03:49:31.633035-07', '2026-06-13 03:44:31.633035-07');
INSERT INTO public.otps VALUES ('055ea0f1-220c-4a3a-ba52-c3a0f8fd5c3b', 'okoltova@gmail.com', '539701', '', true, '2026-06-13 03:50:47.216017-07', '2026-06-13 03:45:47.216017-07');
INSERT INTO public.otps VALUES ('bdced77a-0189-481d-ae31-405fd82e17f2', 'oktovaaaaa@gmail.com', '418218', '', true, '2026-06-13 03:59:58.468672-07', '2026-06-13 03:54:58.470822-07');
INSERT INTO public.otps VALUES ('df186f37-cff2-40bb-b1bb-df3f70eddc96', 'okoltova@gmail.com', '901865', 'LOGIN', true, '2026-06-13 08:11:19.722025-07', '2026-06-13 08:06:19.722025-07');
INSERT INTO public.otps VALUES ('90974289-6fd4-46d0-82ef-cac4f4fdfacf', 'videntiiii@gmail.com', '992353', '', false, '2026-06-13 20:52:42.813486-07', '2026-06-13 20:47:42.814162-07');
INSERT INTO public.otps VALUES ('c2f09fa3-f86e-4ff9-b7d9-e03a6a289339', 'oktovaaaaa@gmail.com', '530473', '', true, '2026-06-15 07:34:55.827275-07', '2026-06-15 07:29:55.830734-07');
INSERT INTO public.otps VALUES ('6473c48c-953a-4cfc-af02-51d797683d95', 'okoltova@gmail.com', '991669', 'LOGIN', true, '2026-06-15 08:01:26.182912-07', '2026-06-15 07:56:26.185418-07');
INSERT INTO public.otps VALUES ('a37bfc15-db3a-4f6d-8954-3ecb41da22b6', 'oktovaaaaa@gmail.com', '787668', '', true, '2026-06-16 10:52:37.006866-07', '2026-06-16 10:47:37.009294-07');
INSERT INTO public.otps VALUES ('1a1df908-4045-47fa-bae1-61c50fa64efd', 'okoltova@gmail.com', '306909', 'LOGIN', true, '2026-06-16 11:09:56.836783-07', '2026-06-16 11:04:56.836783-07');
INSERT INTO public.otps VALUES ('61a17d6a-adfd-41c4-b6d9-5ad9cc5b310f', 'okoltova@gmail.com', '197146', 'LOGIN', false, '2026-06-16 11:36:29.01423-07', '2026-06-16 11:31:29.019249-07');
INSERT INTO public.otps VALUES ('238439eb-893b-4c72-9024-ce85768183e2', 'okoltova@gmail.com', '206432', '', false, '2026-06-16 11:37:16.160992-07', '2026-06-16 11:32:16.160992-07');
INSERT INTO public.otps VALUES ('1dcdb936-0256-48ce-a7da-ddbdb9484376', 'okoltova@gmail.com', '128145', '', false, '2026-06-16 11:41:09.741396-07', '2026-06-16 11:36:09.741396-07');
INSERT INTO public.otps VALUES ('96a6fc4c-b2b5-4156-8bea-9d4332d9e961', 'okoltova@gmail.com', '305293', '', false, '2026-06-16 11:44:41.554655-07', '2026-06-16 11:39:41.554655-07');
INSERT INTO public.otps VALUES ('c6528ee1-e0b8-4458-9209-3bcc272c1391', 'oktovaaaaa@gmail.com', '576759', '', true, '2026-06-16 19:10:01.719114-07', '2026-06-16 19:05:01.719622-07');
INSERT INTO public.otps VALUES ('608633a2-69e2-4290-9b58-edd3567935a5', 'okoltova@gmail.com', '966905', 'LOGIN', false, '2026-06-16 20:02:13.540816-07', '2026-06-16 19:57:13.545216-07');
INSERT INTO public.otps VALUES ('6442a734-a3d2-4397-b9ef-0dc19b980242', 'okoltova@gmail.com', '560579', 'LOGIN', false, '2026-06-16 20:30:18.381765-07', '2026-06-16 20:25:18.38247-07');
INSERT INTO public.otps VALUES ('e8a0a6e8-52b2-4888-9a9a-22927b89c9e2', 'okoltova@gmail.com', '343605', '', false, '2026-06-16 20:30:56.394432-07', '2026-06-16 20:25:56.39495-07');
INSERT INTO public.otps VALUES ('d63e3036-e7a4-4c4e-adc9-6d983521312f', 'okoltova@gmail.com', '731874', 'LOGIN', false, '2026-06-16 20:32:13.20111-07', '2026-06-16 20:27:13.201904-07');
INSERT INTO public.otps VALUES ('a3a33096-cb97-4130-893a-d85ea61fc8b3', 'okoltova@gmail.com', '950299', '', false, '2026-06-16 20:32:44.481572-07', '2026-06-16 20:27:44.481572-07');
INSERT INTO public.otps VALUES ('754ba899-a44f-4121-a496-2504978c21ea', 'sigoelangbatoe@gmail.com', '624240', '', false, '2026-06-16 20:40:38.675671-07', '2026-06-16 20:35:38.676196-07');
INSERT INTO public.otps VALUES ('a5011397-33da-4128-af1d-2a4702d71b92', 'oktovaaaaa@gmail.com', '985104', '', true, '2026-06-21 10:05:32.709667-07', '2026-06-21 10:00:32.712547-07');
INSERT INTO public.otps VALUES ('f26ce41c-78f7-4480-a31f-e9d40bea58d3', 'okoltova@gmail.com', '852639', 'LOGIN', true, '2026-06-21 10:13:54.468626-07', '2026-06-21 10:08:54.468626-07');


--
-- Data for Name: positions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.positions VALUES ('1e332dec-14d9-4516-923a-63f99c95fc71', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'Owner', 0, '', '2026-06-13 03:44:02.629662-07', '2026-06-13 03:44:02.629662-07');
INSERT INTO public.positions VALUES ('bc8c7e38-0e7e-4304-a1f2-307a95ce0a03', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'HRD', 1000000000, 'qwdsdasdsdf', '2026-06-13 03:56:49.33749-07', '2026-06-13 03:56:49.33749-07');


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.sessions VALUES ('e9ab85de-9b3e-4abc-ab69-12d807106472', 'SUPER-ADMIN-ID', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb21wYW55X2lkIjoiU1lTVEVNIiwiZXhwIjoxNzgxNDIzNDc5LCJyb2xlIjoiU1VQRVJfQURNSU4iLCJ1c2VyX2lkIjoiU1VQRVItQURNSU4tSUQifQ.9sk_lbAP_LpGOBZLu2O8Kr0ILJzFRqGbJyvAgrmNt7M', 'web-zgts81k2rcs', 'Chrome (Windows)', false, '2026-06-13 00:51:19.837191-07', '2026-06-14 00:51:19.837191-07', '2026-06-13 00:51:19.837191-07');
INSERT INTO public.sessions VALUES ('5cfc0253-1635-441a-83c7-69edfaf9d196', '859f8da5-0ea0-4ed7-84b8-557878c134a2', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb21wYW55X2lkIjoiZWFhMTEyM2EtYjdmZS00MmU0LWE5NGEtYmFmYzU1ZWFlZjk1IiwiZXhwIjoxNzgyMTQ3NjgyLCJyb2xlIjoiQURNSU4iLCJ1c2VyX2lkIjoiODU5ZjhkYTUtMGVhMC00ZWQ3LTg0YjgtNTU3ODc4YzEzNGEyIn0.Cs4265j1HApxs2tjX3aAlikdhZAh0D4EaxeoT1khk2g', 'web-zgts81k2rcs', 'Chrome (Windows)', false, '2026-06-21 10:01:22.777269-07', '2026-06-22 10:01:22.777269-07', '2026-06-13 03:44:58.7755-07');


--
-- Data for Name: testimonials; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.testimonials VALUES (1, NULL, '3rfewgf', 5, 'werwerwerwe', '/uploads/1c2c2a7f-63dc-40b2-a2a7-f1c1214766c0_1781346139936.jpeg', true, '2026-06-13 03:22:20.484602-07');


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users VALUES ('SUPER-ADMIN-ID', 'SYSTEM', NULL, 'Super Admin', 'videntiiii@gmail.com', '$2a$14$ebxi7hb4pmi4SMYxWJYv1OJEwPuha8se7TznYlM1vS5aMVUn3I.qO', '', '', '', '', '', '', '', 'SUPER_ADMIN', 'ACTIVE', '', '', '', '', '', NULL, 0, NULL, '2026-06-13 00:22:37.879184-07', '2026-06-21 10:58:34.439023-07');
INSERT INTO public.users VALUES ('859f8da5-0ea0-4ed7-84b8-557878c134a2', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '1e332dec-14d9-4516-923a-63f99c95fc71', 'Oktova Samosir', 'oktovaaaaa@gmail.com', '$2a$14$wYr8ipdaKhBN3lsqF/49wuaUiu3H4EjGloVpKNVmT076tMkoVmEqO', '$2a$10$jLexoAqU2V6iFYHBMIO4EezKnj5ErEeHtfHhxzLIsFtycj6jffOAW', '0881080811110', 'Kediri', '2000-01-18', 'Balige', '', '', 'ADMIN', 'ACTIVE', '', '', '', '', '', NULL, 0, NULL, '2026-06-13 03:44:02.63067-07', '2026-06-13 03:44:02.63067-07');
INSERT INTO public.users VALUES ('07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'bc8c7e38-0e7e-4304-a1f2-307a95ce0a03', 'Okoltova', 'okoltova@gmail.com', '$2a$14$xIm.I1pNft.SAI2XcE9lveNo9/JUFmQs1/TUkmsLcPYwP1D6zhFKK', '$2a$10$ZOh407xDkgeh6JWJWy.oEO2ojGaRO649.ASZx9aeOTCR9Rj/R38RC', '0881080811110', 'Balige', '2000-01-12', 'Balige', '', 'eOLJ0yBYRuOf2lYVersw2y:APA91bHW3onmGIeJw4IglWAphZIShTfX_7LvDSMKt2zvD_dpRSdmGtmlwaMkmwKqg5-RUIYocyiHwl872z1iw2mWzVFczsoPK2O9BZHj6sD3Sx-MennZQ1I', 'EMPLOYEE', 'ACTIVE', '', '1782061193997', 'Mandiri', '100110001', '[1.1207719,0.9126593,1.2098266,-0.5668856,-0.2703379,1.4556952,-0.8032554,-0.7509675,0.55196893,-0.21761677,0.18949585,0.15935937,-0.45563316,-0.21215408,-1.3440886,0.30266988,0.9202639,-0.22201088,0.9508314,-0.9438478,0.09134332,-2.2290332,0.8756779,0.9357548,-0.013222599,-0.9103936,-1.1052251,-0.700463,0.42169148,0.40565044,1.8049746,-0.3981052,-0.766935,-1.5567287,-0.06201334,-0.95096904,-0.16840644,0.59943324,-0.6247894,-1.3917499,0.48170575,-0.6453255,1.4200736,-0.0054976763,-0.94202363,0.91495407,0.5585769,0.9199332,0.017591571,0.45933628,2.0891356,0.77290255,0.2565899,0.749807,0.6541742,0.4061165,-0.5102259,-0.18873963,0.44966635,0.27033454,-0.020135213,0.70517564,0.3405925,0.70220524,0.88630646,-0.56560117,0.11216004,-0.845821,-0.5722488,-0.21965234,-1.1087811,-1.2639225,-0.06359477,-1.8693348,-2.312765,0.80740374,-0.6907581,-2.398169,2.870074,-0.1940062,-0.12495799,-1.234894,-0.03684609,0.4819758,-0.8168621,-0.30520028,0.16687915,-0.5321039,0.18061946,0.49307427,0.15783384,0.71388024,0.45478305,0.17604223,-0.3515219,1.235952,0.26846778,-0.9163332,-0.12697008,-0.14771947,0.6701703,0.118246555,0.29231542,0.45930535,0.24063635,0.12826692,-1.5397105,-1.8761089,-0.8695749,0.5943904,1.3084223,1.0048763,0.6483868,-0.8402544,-1.1792262,0.64597917,0.43342,-1.1993501,-0.925553,0.48678845,-0.80755126,0.50608796,-0.1887699,0.3033433,-0.19914007,0.6224171,-0.10708181,-0.7643081,0.3435232,1.1700939,2.2670949,0.37064153,-0.28491428,-0.42688957,-1.2782873,0.28478855,0.46919656,0.14542592,0.82071173,0.64823085,0.48666304,-0.3972944,-0.94275886,-1.3591901,-1.4004638,0.8162648,-0.30664793,0.25948432,0.4125704,0.7890534,-0.8761773,0.24367857,0.50243443,1.3057083,1.2643979,-0.48816624,-0.5771948,-2.308709,-0.14931624,1.0799654,0.9606632,0.82229596,-0.679313,0.11738219,0.5053931,1.3435733,-1.0791147,-1.0596172,-1.5984211,0.33363724,0.18401003,-1.5648706,0.20362219,1.8019425,0.9110284,0.8437298,-0.004124701,1.6549441,1.6650465,0.7419015,1.3880078,0.9398674,-0.8937828,0.071731515,-0.8357962,-0.58242875,0.17729104,-1.3263547,1.4275258,-0.8971488,-0.4447183,-0.05535195,1.8602422,0.7209047,-1.3553793,-1.7037399,-1.4680068,0.23481917,1.1956613,-0.3638088,0.40342623,-0.7441036,1.4806433,-0.87387514,2.6068337,0.82799846,1.2179253,-0.50465715,0.27389964,0.6254822,-1.673205,0.018896744,-0.42619458,-1.0674084,0.36609903,1.3061584,-0.3333846,-0.38010627,-1.5098455,0.70861024,2.5012517,1.2956057,-0.3657624,0.17413525,-0.56966174,-0.8689806,-1.3279027,-0.66187054,0.45246476,-0.7175317,-0.8627998,-1.279258,0.74225193,0.26343316,-1.2351115,-0.67269677,-2.267681,1.4140738,-1.3886913,-0.021134805,-0.004731131,-1.5963554,-1.1232865,-0.43035278,2.2516625,1.2590996,-0.06233375,-0.27593857,-0.9419466,-0.19287567,-0.10155477,0.4404307,0.3510055,0.20640893,1.006051,-1.0255171,-1.3715498,0.28879485,1.3032961,2.0152586,-0.47571453,-1.2232931,0.20138197,-0.41438237,0.9296352,-0.3620651,-0.22629333,0.370885,0.685338,-1.3865938,0.7968562,-0.34255573,0.55731755,0.563043,0.14021268,0.21942797,-0.50390816,0.5430641,2.150064,-0.14005224,-0.97987354,0.693881,0.68151253,-0.36511058,1.363597,-0.1902726,-0.5741547,-1.3980142,1.1508468,-0.6039119,0.9023787,0.458277,1.2562693,1.4327614,0.13872722,-0.87681836,-0.7074223,-0.640958,0.022049237,0.27018338,-0.4700424,-0.41286126,-0.73764884,2.0408008,0.30284867,0.5003173,-1.2449881,0.47049767,0.13998121,-0.2567188,0.41325435,0.3990062,-0.006187141,1.6621351,1.3808619,1.1087517,0.9795079,0.5854128,-0.15125644,-1.3111045,0.30463266,-3.1919866,-0.48630685,0.89397156,-1.1012194,0.70835525,-1.1495605,1.7949129,-0.66446555,0.2530052,-0.38633654,-1.2763433,-1.3831159,0.50690985,-0.55842817,0.113633774,-1.1969467,-0.8436182,0.4286674,1.222512,-0.563401,0.8129814,0.2814424,-1.7584345,-1.4905945,0.37057418,0.15519209,0.22425826,0.34624362,0.5307883,1.9075896,0.42349362,0.206392,-0.8894488,-0.94267815,-0.28119397,0.22779736,-0.40643635,0.36162603,-0.8104828,0.18994626,0.28215498,-0.86789787,0.052875064,0.580851,-0.9897763,0.3401986,-0.15573342,0.9103001,-0.38408,1.3754326,2.3464646,-1.231678,-1.2709213,0.6193847,0.48222333,-1.075134,0.012198359,0.42217198,-0.06779256,-1.4329469,-0.14978547,0.3833211,0.8609268,0.3146364,0.56150776,1.0764219,0.2514854,0.64610165,-0.8343561,-0.69405764,-0.7854825,0.17289396,0.72246045,0.5527665,1.6913815,-0.036836654,0.76910555,-0.88319033,-0.30991608,-0.45129877,-1.7076114,-0.11216613,0.44434348,-1.5158947,1.2583282,-0.6692414,0.5582768,-0.76357585,-0.13612981,-0.48821408,0.13026932,0.9371213,-1.1860845,0.89594316,0.33763522,0.5716299,-0.597984,0.33494806,-1.4116724,-0.22322007,0.5538207,-0.2792618,0.4198249,0.020191956,0.41294178,-1.011089,0.8225583,-0.88504916,0.8486352,-0.5665962,1.7815044,1.0800383,0.4473589,0.051748075,-0.9939704,-0.39654255,-0.12166347,-0.20743462,0.36696282,0.31313452,-0.41386333,-1.3152449,-0.5863405,-0.07797481,-1.0488069,0.07362262,0.25074813,1.0901706,0.5947198,-0.19010147,-0.79862744,-1.5502746,1.3697847,0.7271026,0.1411514,0.15721083,-2.7996423,-1.2956475,-0.23840931,-0.17198293,0.2373311,-0.6570356,0.9913052,1.3107898,0.94384634,-1.1432683,-0.32035705,-0.79981184,-0.9310873,0.16035691,-0.16875106,-0.64528114,0.82677066,-0.66442466,-1.2934912,2.1232784,-0.8219944,0.07957338,0.71331877,0.6134652,-0.86438835,1.1867185,0.23348503,-1.3878989,-0.16704121,0.93600166,2.1281419,2.0673325,-0.6085377,-0.6513777,-0.7100093,-1.2485359,0.6998446,-0.2604607,0.060066245,0.34634328,-0.38704178,0.51476747,1.0236061,-1.6058375,0.7604754,1.6348966,-0.07772335,-1.6561638,-0.6502997,0.5433016,-0.45344788,-0.7162412,0.12050954,0.46627226,0.22326283]', NULL, 0, NULL, '2026-02-28 09:00:00-08', '2026-06-21 10:26:39.041038-07');


--
-- Name: testimonials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.testimonials_id_seq', 1, true);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: company_locations company_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company_locations
    ADD CONSTRAINT company_locations_pkey PRIMARY KEY (id);


--
-- Name: invite_tokens invite_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invite_tokens
    ADD CONSTRAINT invite_tokens_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: otps otps_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.otps
    ADD CONSTRAINT otps_pkey PRIMARY KEY (id);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: testimonials testimonials_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testimonials
    ADD CONSTRAINT testimonials_pkey PRIMARY KEY (id);


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
-- Name: idx_company_locations_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_company_locations_company_id ON public.company_locations USING btree (company_id);


--
-- Name: idx_notifications_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_company_id ON public.notifications USING btree (company_id);


--
-- Name: idx_notifications_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: idx_positions_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_positions_company_id ON public.positions USING btree (company_id);


--
-- Name: idx_sessions_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_user_id ON public.sessions USING btree (user_id);


--
-- Name: idx_testimonials_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_testimonials_user_id ON public.testimonials USING btree (user_id);


--
-- Name: company_locations fk_company_locations_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company_locations
    ADD CONSTRAINT fk_company_locations_company FOREIGN KEY (company_id) REFERENCES public.companies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: invite_tokens fk_invite_tokens_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invite_tokens
    ADD CONSTRAINT fk_invite_tokens_company FOREIGN KEY (company_id) REFERENCES public.companies(id) ON UPDATE CASCADE ON DELETE CASCADE;


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
-- Name: positions fk_positions_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT fk_positions_company FOREIGN KEY (company_id) REFERENCES public.companies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: sessions fk_sessions_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: testimonials fk_testimonials_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testimonials
    ADD CONSTRAINT fk_testimonials_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


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

