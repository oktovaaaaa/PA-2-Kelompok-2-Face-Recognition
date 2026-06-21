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
-- Name: attendance_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attendance_settings (
    id text NOT NULL,
    company_id text,
    check_in_start text,
    check_in_end text,
    check_out_start text,
    check_out_end text,
    alpha_penalty numeric,
    late_penalty numeric,
    late_penalty_tiers text,
    early_leave_penalty numeric,
    work_days text DEFAULT 'Monday,Tuesday,Wednesday,Thursday,Friday'::text,
    latitude numeric,
    longitude numeric,
    radius numeric,
    updated_at timestamp with time zone
);


ALTER TABLE public.attendance_settings OWNER TO postgres;

--
-- Name: attendances; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attendances (
    id text NOT NULL,
    user_id text,
    company_id text,
    date text,
    check_in_latitude numeric,
    check_in_longitude numeric,
    check_in_location_id text,
    check_in_distance numeric,
    check_out_latitude numeric,
    check_out_longitude numeric,
    check_out_location_id text,
    check_out_distance numeric,
    check_in_time timestamp with time zone,
    check_out_time timestamp with time zone,
    status text,
    salary_deduction numeric,
    notes text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.attendances OWNER TO postgres;

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
-- Name: company_wifis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.company_wifis (
    id text NOT NULL,
    company_id text NOT NULL,
    location_id text,
    name text,
    bss_id text NOT NULL,
    is_active boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.company_wifis OWNER TO postgres;

--
-- Name: holidays; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.holidays (
    id text NOT NULL,
    company_id text,
    name text,
    description text,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    created_at timestamp with time zone
);


ALTER TABLE public.holidays OWNER TO postgres;

--
-- Name: leave_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.leave_requests (
    id text NOT NULL,
    user_id text,
    company_id text,
    type text,
    title text,
    description text,
    photo_url text,
    status text,
    admin_note text,
    confirmed_honest boolean,
    is_deleted_by_employee boolean,
    is_deleted_by_admin boolean,
    dates text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.leave_requests OWNER TO postgres;

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
-- Data for Name: attendance_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.attendance_settings VALUES ('a014988f-10b9-4f2f-8eec-7472bc74707b', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '00:00', '01:00', '10:00', '12:00', 1000000, 2000000, '[{"hours":1,"penalty":100000},{"hours":2,"penalty":200000},{"hours":3,"penalty":300000}]', 1000000, 'Monday,Tuesday,Wednesday,Thursday,Friday', 0, 0, 100, '2026-06-21 10:10:58.423814-07');


--
-- Data for Name: attendances; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.attendances VALUES ('95df0e36-3baa-449f-9ccb-e4ea1d504d60', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-02', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-01 16:47:00-08', '2026-03-02 01:23:00-08', 'PRESENT', 0, '', '2026-03-01 09:00:00-08', '2026-03-01 09:00:00-08');
INSERT INTO public.attendances VALUES ('50e25fa2-443a-407b-9760-380709579fcc', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-03', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-02 16:43:00-08', '2026-03-03 01:25:00-08', 'PRESENT', 0, '', '2026-03-02 09:00:00-08', '2026-03-02 09:00:00-08');
INSERT INTO public.attendances VALUES ('7519428f-4233-43b7-b509-1db9a213dc92', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-04', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-03 17:15:00-08', '2026-03-03 22:26:00-08', 'EARLY_LEAVE', 15000, '', '2026-03-03 09:00:00-08', '2026-03-03 09:00:00-08');
INSERT INTO public.attendances VALUES ('d7c1a1b1-740a-4ea2-b5fe-6f0bee1e41a1', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-05', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-04 16:43:00-08', '0001-12-31 16:07:02-07:52:58 BC', 'PRESENT', 0, '', '2026-03-04 09:00:00-08', '2026-03-04 09:00:00-08');
INSERT INTO public.attendances VALUES ('c3ae972a-d3b3-4918-9312-4e434e9f215f', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-06', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-05 16:15:00-08', '2026-03-06 01:43:00-08', 'PRESENT', 0, '', '2026-03-05 09:00:00-08', '2026-03-05 09:00:00-08');
INSERT INTO public.attendances VALUES ('8417b58b-c6d0-41a1-aed3-ae931e25fcbc', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-09', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-08 19:18:00-07', '2026-03-09 03:05:00-07', 'LATE', 25000, '', '2026-03-08 10:00:00-07', '2026-03-08 10:00:00-07');
INSERT INTO public.attendances VALUES ('a9035dff-47e4-4a30-ae17-a812e98c56cf', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-10', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-09 19:46:00-07', '2026-03-10 03:05:00-07', 'LATE', 25000, '', '2026-03-09 10:00:00-07', '2026-03-09 10:00:00-07');
INSERT INTO public.attendances VALUES ('fa2b5d92-2503-44af-b561-1e4ed952624f', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-11', 0, 0, NULL, 0, 0, 0, NULL, 0, NULL, NULL, 'LEAVE', 0, '', '2026-03-10 10:00:00-07', '2026-03-10 10:00:00-07');
INSERT INTO public.attendances VALUES ('932f995f-8f3c-41de-b089-244f7d661b55', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-13', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-12 17:54:00-07', '2026-03-13 02:54:00-07', 'PRESENT', 0, '', '2026-03-12 10:00:00-07', '2026-03-12 10:00:00-07');
INSERT INTO public.attendances VALUES ('27155561-eaf6-4c07-be7b-fd1354f59211', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-16', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-15 17:04:00-07', '2026-03-16 02:26:00-07', 'PRESENT', 0, '', '2026-03-15 10:00:00-07', '2026-03-15 10:00:00-07');
INSERT INTO public.attendances VALUES ('1b1fdc30-3bfe-498b-a57b-0fd8eff70423', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-17', 0, 0, NULL, 0, 0, 0, NULL, 0, NULL, NULL, 'LEAVE', 0, '', '2026-03-16 10:00:00-07', '2026-03-16 10:00:00-07');
INSERT INTO public.attendances VALUES ('947ab312-2953-4adf-98c0-8f060dba3449', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-18', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-17 17:07:00-07', '2026-03-18 02:49:00-07', 'PRESENT', 0, '', '2026-03-17 10:00:00-07', '2026-03-17 10:00:00-07');
INSERT INTO public.attendances VALUES ('33e742f9-b48e-4392-be44-013340664571', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-19', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-18 17:02:00-07', '0001-12-31 16:07:02-07:52:58 BC', 'PRESENT', 0, '', '2026-03-18 10:00:00-07', '2026-03-18 10:00:00-07');
INSERT INTO public.attendances VALUES ('8ac81838-3676-4924-88c0-b2751a3feabb', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-23', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-22 17:58:00-07', '2026-03-23 02:04:00-07', 'PRESENT', 0, '', '2026-03-22 10:00:00-07', '2026-03-22 10:00:00-07');
INSERT INTO public.attendances VALUES ('dd8bfd14-58b5-4c5e-abc6-c1a0c90c1b1a', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-24', 0, 0, NULL, 0, 0, 0, NULL, 0, NULL, NULL, 'SICK', 0, '', '2026-03-23 10:00:00-07', '2026-03-23 10:00:00-07');
INSERT INTO public.attendances VALUES ('48948d4f-e84e-4faa-8c44-a67726f4ca60', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-25', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-24 17:47:00-07', '0001-12-31 16:07:02-07:52:58 BC', 'PRESENT', 0, '', '2026-03-24 10:00:00-07', '2026-03-24 10:00:00-07');
INSERT INTO public.attendances VALUES ('b46069e5-0417-4291-9c54-e07fe4288cf6', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-26', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-25 18:15:00-07', '2026-03-26 00:14:00-07', 'EARLY_LEAVE', 15000, '', '2026-03-25 10:00:00-07', '2026-03-25 10:00:00-07');
INSERT INTO public.attendances VALUES ('b7a1ebfc-b6ae-4dc0-bd58-6e31e8d684c9', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-27', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-26 17:56:00-07', '2026-03-27 02:12:00-07', 'PRESENT', 0, '', '2026-03-26 10:00:00-07', '2026-03-26 10:00:00-07');
INSERT INTO public.attendances VALUES ('656f570e-ca67-435f-b8a9-48788a18c711', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-30', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-29 18:15:00-07', '2026-03-30 01:12:00-07', 'EARLY_LEAVE', 15000, '', '2026-03-29 10:00:00-07', '2026-03-29 10:00:00-07');
INSERT INTO public.attendances VALUES ('7f0fecfb-726e-4ca4-9b20-2311f200a58c', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-03-31', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-30 19:54:00-07', '2026-03-31 03:05:00-07', 'LATE', 25000, '', '2026-03-30 10:00:00-07', '2026-03-30 10:00:00-07');
INSERT INTO public.attendances VALUES ('95fd5852-d1b4-425d-8e8f-f6c59e323b24', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-01', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-03-31 17:52:00-07', '2026-04-01 02:04:00-07', 'PRESENT', 0, '', '2026-03-31 10:00:00-07', '2026-03-31 10:00:00-07');
INSERT INTO public.attendances VALUES ('06c3d07c-1f12-4833-b9e7-7f7ddec624ba', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-02', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-01 18:15:00-07', '2026-04-02 01:02:00-07', 'EARLY_LEAVE', 15000, '', '2026-04-01 10:00:00-07', '2026-04-01 10:00:00-07');
INSERT INTO public.attendances VALUES ('cf0db998-be68-44df-bbb0-46dd2331d544', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-03', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-02 17:18:00-07', '0001-12-31 16:07:02-07:52:58 BC', 'PRESENT', 0, '', '2026-04-02 10:00:00-07', '2026-04-02 10:00:00-07');
INSERT INTO public.attendances VALUES ('c2d3f918-7c2a-4f1f-97e0-c23891b6c43e', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-06', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-05 17:47:00-07', '2026-04-06 02:04:00-07', 'PRESENT', 0, '', '2026-04-05 10:00:00-07', '2026-04-05 10:00:00-07');
INSERT INTO public.attendances VALUES ('8cfc275f-50d5-4c7d-8475-6b8de851c0c8', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-07', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-06 19:16:00-07', '2026-04-07 03:05:00-07', 'LATE', 25000, '', '2026-04-06 10:00:00-07', '2026-04-06 10:00:00-07');
INSERT INTO public.attendances VALUES ('94e5ea92-6fbb-4430-9d86-1e485b96cd38', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-08', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-07 19:50:00-07', '2026-04-08 03:05:00-07', 'LATE', 25000, '', '2026-04-07 10:00:00-07', '2026-04-07 10:00:00-07');
INSERT INTO public.attendances VALUES ('e390ab77-36e6-4245-9365-4270f1f63a1d', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-09', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-08 17:56:00-07', '2026-04-09 02:03:00-07', 'PRESENT', 0, '', '2026-04-08 10:00:00-07', '2026-04-08 10:00:00-07');
INSERT INTO public.attendances VALUES ('9f299d6c-c280-4573-93d6-637c1b05b346', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-10', 0, 0, NULL, 0, 0, 0, NULL, 0, NULL, NULL, 'SICK', 0, '', '2026-04-09 10:00:00-07', '2026-04-09 10:00:00-07');
INSERT INTO public.attendances VALUES ('455ab9b0-a05b-4c6c-b98d-ff42f0fcf3f4', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-13', 0, 0, NULL, 0, 0, 0, NULL, 0, NULL, NULL, 'SICK', 0, '', '2026-04-12 10:00:00-07', '2026-04-12 10:00:00-07');
INSERT INTO public.attendances VALUES ('e4803905-39ee-49ee-b562-82ed0c2059d1', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-14', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-13 17:47:00-07', '2026-04-14 02:30:00-07', 'PRESENT', 0, '', '2026-04-13 10:00:00-07', '2026-04-13 10:00:00-07');
INSERT INTO public.attendances VALUES ('570a79dd-d62d-405e-8748-6601fee26010', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-15', 0, 0, NULL, 0, 0, 0, NULL, 0, NULL, NULL, 'SICK', 0, '', '2026-04-14 10:00:00-07', '2026-04-14 10:00:00-07');
INSERT INTO public.attendances VALUES ('2e32d684-aaff-4569-9df9-4666bc95fad2', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-16', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-15 19:09:00-07', '2026-04-16 03:05:00-07', 'LATE', 25000, '', '2026-04-15 10:00:00-07', '2026-04-15 10:00:00-07');
INSERT INTO public.attendances VALUES ('6503125e-9042-466d-ae3d-cb42e42169b3', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-17', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-16 17:44:00-07', '2026-04-17 02:53:00-07', 'PRESENT', 0, '', '2026-04-16 10:00:00-07', '2026-04-16 10:00:00-07');
INSERT INTO public.attendances VALUES ('f1f03ae8-a508-4791-bf09-a099bcc7da13', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-20', 0, 0, NULL, 0, 0, 0, NULL, 0, NULL, NULL, 'SICK', 0, '', '2026-04-19 10:00:00-07', '2026-04-19 10:00:00-07');
INSERT INTO public.attendances VALUES ('5b8ab970-1da1-4ac9-9ad1-b90d6c53bc61', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-21', 0, 0, NULL, 0, 0, 0, NULL, 0, NULL, NULL, 'LEAVE', 0, '', '2026-04-20 10:00:00-07', '2026-04-20 10:00:00-07');
INSERT INTO public.attendances VALUES ('b909f042-6f46-4146-9458-881ff404606e', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-23', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-22 17:19:00-07', '0001-12-31 16:07:02-07:52:58 BC', 'PRESENT', 0, '', '2026-04-22 10:00:00-07', '2026-04-22 10:00:00-07');
INSERT INTO public.attendances VALUES ('787c7fd6-7a20-4b51-aaa1-50beeffa7588', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-24', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-23 19:10:00-07', '2026-04-24 03:05:00-07', 'LATE', 25000, '', '2026-04-23 10:00:00-07', '2026-04-23 10:00:00-07');
INSERT INTO public.attendances VALUES ('57d64002-0702-4a32-9b81-1dd915404afa', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-27', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-26 17:23:00-07', '2026-04-27 02:33:00-07', 'PRESENT', 0, '', '2026-04-26 10:00:00-07', '2026-04-26 10:00:00-07');
INSERT INTO public.attendances VALUES ('c4b2ed47-7d0c-4a38-990c-b0acc600eb77', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-28', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-27 17:38:00-07', '0001-12-31 16:07:02-07:52:58 BC', 'PRESENT', 0, '', '2026-04-27 10:00:00-07', '2026-04-27 10:00:00-07');
INSERT INTO public.attendances VALUES ('c7104069-f911-460c-8f2c-1913bce6403f', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-29', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-28 17:03:00-07', '2026-04-29 02:51:00-07', 'PRESENT', 0, '', '2026-04-28 10:00:00-07', '2026-04-28 10:00:00-07');
INSERT INTO public.attendances VALUES ('9abb610f-5e7a-497f-90d3-5a5022215d64', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-04-30', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-29 17:55:00-07', '2026-04-30 02:11:00-07', 'PRESENT', 0, '', '2026-04-29 10:00:00-07', '2026-04-29 10:00:00-07');
INSERT INTO public.attendances VALUES ('979edb32-c801-4fdc-bd82-652bb0a6d8fd', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-01', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-04-30 19:23:00-07', '2026-05-01 03:05:00-07', 'LATE', 25000, '', '2026-04-30 10:00:00-07', '2026-04-30 10:00:00-07');
INSERT INTO public.attendances VALUES ('9e782c64-fc32-442f-aa19-2a1ce39580c1', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-05', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-04 17:35:00-07', '2026-05-05 02:48:00-07', 'PRESENT', 0, '', '2026-05-04 10:00:00-07', '2026-05-04 10:00:00-07');
INSERT INTO public.attendances VALUES ('78684f36-ec05-4a0c-97d9-961e46bfaa16', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-06', 0, 0, NULL, 0, 0, 0, NULL, 0, NULL, NULL, 'LEAVE', 0, '', '2026-05-05 10:00:00-07', '2026-05-05 10:00:00-07');
INSERT INTO public.attendances VALUES ('22b32d05-e9a8-449d-a723-fd90bed96844', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-07', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-06 19:12:00-07', '2026-05-07 03:05:00-07', 'LATE', 25000, '', '2026-05-06 10:00:00-07', '2026-05-06 10:00:00-07');
INSERT INTO public.attendances VALUES ('d1929319-e75d-475c-875b-e6e54b9b5446', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-08', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-07 19:52:00-07', '2026-05-08 03:05:00-07', 'LATE', 25000, '', '2026-05-07 10:00:00-07', '2026-05-07 10:00:00-07');
INSERT INTO public.attendances VALUES ('9c1c4002-160b-449b-a4c8-544c750db20f', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-11', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-10 17:31:00-07', '0001-12-31 16:07:02-07:52:58 BC', 'PRESENT', 0, '', '2026-05-10 10:00:00-07', '2026-05-10 10:00:00-07');
INSERT INTO public.attendances VALUES ('91849f80-2208-4cbe-af9b-a39ac386ff82', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-12', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-11 17:39:00-07', '0001-12-31 16:07:02-07:52:58 BC', 'PRESENT', 0, '', '2026-05-11 10:00:00-07', '2026-05-11 10:00:00-07');
INSERT INTO public.attendances VALUES ('85a830f9-af6d-4034-9c74-8e1e0dde8269', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-13', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-12 17:43:00-07', '0001-12-31 16:07:02-07:52:58 BC', 'PRESENT', 0, '', '2026-05-12 10:00:00-07', '2026-05-12 10:00:00-07');
INSERT INTO public.attendances VALUES ('451364ca-6a87-452f-9ff5-9b57757ff26b', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-14', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-13 18:15:00-07', '2026-05-14 00:03:00-07', 'EARLY_LEAVE', 15000, '', '2026-05-13 10:00:00-07', '2026-05-13 10:00:00-07');
INSERT INTO public.attendances VALUES ('3b46485e-4700-42c4-8908-3516bf3864ff', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-15', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-14 17:30:00-07', '0001-12-31 16:07:02-07:52:58 BC', 'PRESENT', 0, '', '2026-05-14 10:00:00-07', '2026-05-14 10:00:00-07');
INSERT INTO public.attendances VALUES ('fddc3613-784e-4a06-9b61-95047a30f293', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-18', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-17 17:51:00-07', '2026-05-18 02:55:00-07', 'PRESENT', 0, '', '2026-05-17 10:00:00-07', '2026-05-17 10:00:00-07');
INSERT INTO public.attendances VALUES ('c9f821d1-9313-4baf-9e6f-9e470ab6c537', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-19', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-18 17:03:00-07', '2026-05-19 02:24:00-07', 'PRESENT', 0, '', '2026-05-18 10:00:00-07', '2026-05-18 10:00:00-07');
INSERT INTO public.attendances VALUES ('8a5de993-6f67-49bf-a68b-67a7e70211f8', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-20', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-19 19:44:00-07', '2026-05-20 03:05:00-07', 'LATE', 25000, '', '2026-05-19 10:00:00-07', '2026-05-19 10:00:00-07');
INSERT INTO public.attendances VALUES ('5bbc8968-7e64-4e65-92cb-53fffbb31814', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-21', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-20 17:41:00-07', '2026-05-21 02:49:00-07', 'PRESENT', 0, '', '2026-05-20 10:00:00-07', '2026-05-20 10:00:00-07');
INSERT INTO public.attendances VALUES ('f4e3977e-9b94-4de8-8699-ae6fbd2c2f1b', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-22', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-21 17:19:00-07', '2026-05-22 02:27:00-07', 'PRESENT', 0, '', '2026-05-21 10:00:00-07', '2026-05-21 10:00:00-07');
INSERT INTO public.attendances VALUES ('6ab6c075-d24b-4cd1-b863-788e4353fd47', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-25', 0, 0, NULL, 0, 0, 0, NULL, 0, '0001-12-31 16:07:02-07:52:58 BC', '2026-05-25 03:05:00-07', 'LATE', 25000, '', '2026-05-24 10:00:00-07', '2026-05-24 10:00:00-07');
INSERT INTO public.attendances VALUES ('d8c47857-52aa-4be9-a703-e6ee067a1d95', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-26', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-25 19:10:00-07', '2026-05-26 03:05:00-07', 'LATE', 25000, '', '2026-05-25 10:00:00-07', '2026-05-25 10:00:00-07');
INSERT INTO public.attendances VALUES ('0d97aad1-c847-4ce5-a0ef-6f7e5fc6cd92', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-27', 0, 0, NULL, 0, 0, 0, NULL, 0, '0001-12-31 16:07:02-07:52:58 BC', '2026-05-27 03:05:00-07', 'LATE', 25000, '', '2026-05-26 10:00:00-07', '2026-05-26 10:00:00-07');
INSERT INTO public.attendances VALUES ('6a7dfa4f-d169-4ed3-972d-ecec901355c7', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-28', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-27 17:18:00-07', '2026-05-28 02:54:00-07', 'PRESENT', 0, '', '2026-05-27 10:00:00-07', '2026-05-27 10:00:00-07');
INSERT INTO public.attendances VALUES ('da0290bc-b541-435b-8eaf-90b0cb8f40bb', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-05-29', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-28 18:15:00-07', '2026-05-28 23:12:00-07', 'EARLY_LEAVE', 15000, '', '2026-05-28 10:00:00-07', '2026-05-28 10:00:00-07');
INSERT INTO public.attendances VALUES ('259fb4b2-0b36-4ee5-b8b9-c1830bde7585', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-06-01', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-05-31 17:49:00-07', '2026-06-01 02:26:00-07', 'PRESENT', 0, '', '2026-05-31 10:00:00-07', '2026-05-31 10:00:00-07');
INSERT INTO public.attendances VALUES ('4e1afd2f-7020-408a-bc3a-a47a78808263', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-06-02', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-06-01 17:07:00-07', '2026-06-02 02:16:00-07', 'PRESENT', 0, '', '2026-06-01 10:00:00-07', '2026-06-01 10:00:00-07');
INSERT INTO public.attendances VALUES ('dcc59546-8f66-4cb1-8fde-f71c617dc361', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-06-03', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-06-02 19:37:00-07', '2026-06-03 03:05:00-07', 'LATE', 25000, '', '2026-06-02 10:00:00-07', '2026-06-02 10:00:00-07');
INSERT INTO public.attendances VALUES ('421e5770-8ea1-40b1-b229-38329c097024', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-06-04', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-06-03 17:23:00-07', '2026-06-04 02:18:00-07', 'PRESENT', 0, '', '2026-06-03 10:00:00-07', '2026-06-03 10:00:00-07');
INSERT INTO public.attendances VALUES ('2d2b4377-02b0-430f-afef-22e4f26a5077', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-06-05', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-06-04 19:06:00-07', '2026-06-05 03:05:00-07', 'LATE', 25000, '', '2026-06-04 10:00:00-07', '2026-06-04 10:00:00-07');
INSERT INTO public.attendances VALUES ('4c24d08b-d875-4337-9a7c-02c9cc38b2ff', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-06-08', 0, 0, NULL, 0, 0, 0, NULL, 0, NULL, NULL, 'SICK', 0, '', '2026-06-07 10:00:00-07', '2026-06-07 10:00:00-07');
INSERT INTO public.attendances VALUES ('5b5d19aa-6964-4201-840e-b64ae648df4e', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-06-09', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-06-08 17:21:00-07', '0001-12-31 16:07:02-07:52:58 BC', 'PRESENT', 0, '', '2026-06-08 10:00:00-07', '2026-06-08 10:00:00-07');
INSERT INTO public.attendances VALUES ('667990b0-99c6-4f2e-bd4f-a2ec4daa237e', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-06-10', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-06-09 17:49:00-07', '2026-06-10 02:14:00-07', 'PRESENT', 0, '', '2026-06-09 10:00:00-07', '2026-06-09 10:00:00-07');
INSERT INTO public.attendances VALUES ('f46babb7-eab7-4036-8499-50c4eb76760e', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-06-11', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-06-10 19:53:00-07', '2026-06-11 03:05:00-07', 'LATE', 25000, '', '2026-06-10 10:00:00-07', '2026-06-10 10:00:00-07');
INSERT INTO public.attendances VALUES ('73f14a7d-93c2-47d1-966c-4eede107b92f', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-06-12', 0, 0, NULL, 0, 0, 0, NULL, 0, '2026-06-11 18:15:00-07', '2026-06-12 00:53:00-07', 'EARLY_LEAVE', 15000, '', '2026-06-11 10:00:00-07', '2026-06-11 10:00:00-07');
INSERT INTO public.attendances VALUES ('a9e49aa7-7513-4e4d-bbab-163d3b14e443', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-06-15', 2.3862533, 99.1473067, 'd269d563-ca1f-4eee-a0d9-35a193d92ef7', 19.66151708018772, 0, 0, NULL, 0, '2026-06-15 08:12:11.942883-07', NULL, 'LATE', 300000, '', '2026-06-15 08:12:11.946621-07', '2026-06-15 08:12:11.946621-07');
INSERT INTO public.attendances VALUES ('57ae8859-59d4-42e1-8dc4-3bbd7cfc35d5', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '2026-06-22', 2.3862533, 99.1473067, 'd269d563-ca1f-4eee-a0d9-35a193d92ef7', 19.66151708018772, 0, 0, NULL, 0, '2026-06-21 10:39:53.402086-07', NULL, 'PRESENT', 0, '', '2026-06-21 10:39:53.40643-07', '2026-06-21 10:39:53.40643-07');


--
-- Data for Name: companies; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.companies VALUES ('b1c7a24d-c446-4bb2-bc9b-d19cb70c5fb6', 'Astra', 'Balige', 'astra@gmail.com', '0881080811110', '', 0, 0, 'ACTIVE', '2026-06-13 00:41:38.201761-07');
INSERT INTO public.companies VALUES ('SYSTEM', 'System Administration', 'System', 'videntiiii@gmail.com', '000', '', 0, 0, 'ACTIVE', '2026-06-13 00:22:37.024942-07');
INSERT INTO public.companies VALUES ('eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'Astra International', 'Balige', 'astra@gmail.com', '0881080811110', '', 0, 0, 'ACTIVE', '2026-06-13 03:44:02.627152-07');


--
-- Data for Name: company_locations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.company_locations VALUES ('d269d563-ca1f-4eee-a0d9-35a193d92ef7', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'IT Del', 2.3860897862273514, 99.14723934632012, 100, true, '2026-06-15 08:04:38.846236-07', '2026-06-15 08:05:01.332607-07');


--
-- Data for Name: company_wifis; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: holidays; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: leave_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.leave_requests VALUES ('c7a8f7b6-1f58-4743-bac4-c12c60ca2604', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'IZIN', 'Urusan Keluarga', 'Izin mengurus dokumen pernikahan keluarga.', '', 'APPROVED', '', true, false, false, '["2026-04-10"]', '2026-04-08 18:00:00-07', '2026-06-13 03:51:11.355689-07');
INSERT INTO public.leave_requests VALUES ('b448d8ae-960b-473d-a1de-4a41864e5eda', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'SAKIT', 'Sakit Demam Tinggi', 'Surat sakit terlampir, mengalami flu dan demam tinggi.', '', 'APPROVED', '', true, false, false, '["2026-05-18"]', '2026-05-16 19:00:00-07', '2026-06-13 03:51:11.35702-07');
INSERT INTO public.leave_requests VALUES ('9f6a3080-0576-4c16-925c-f3ecff39f90e', '07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'IZIN', 'Wisuda Kakak', 'Izin menghadiri upacara wisuda kakak kandung.', '', 'PENDING', '', true, false, false, '["2026-06-15"]', '2026-06-12 20:00:00-07', '2026-06-13 03:51:11.358085-07');


--
-- Data for Name: positions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.positions VALUES ('1e332dec-14d9-4516-923a-63f99c95fc71', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'Owner', 0, '', '2026-06-13 03:44:02.629662-07', '2026-06-21 10:58:34.606616-07');
INSERT INTO public.positions VALUES ('bc8c7e38-0e7e-4304-a1f2-307a95ce0a03', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'HRD', 1000000000, 'qwdsdasdsdf', '2026-06-13 03:56:49.33749-07', '2026-06-21 10:58:34.682686-07');
INSERT INTO public.positions VALUES ('774acf97-2208-4ebf-8f6b-20ad635ea902', 'b1c7a24d-c446-4bb2-bc9b-d19cb70c5fb6', 'Owner', 0, '', '2026-06-13 00:41:38.20277-07', '2026-06-13 03:21:46.392971-07');
INSERT INTO public.positions VALUES ('421c7ecc-38da-4e9e-b919-e771b3d2f0c5', 'b1c7a24d-c446-4bb2-bc9b-d19cb70c5fb6', 'HRD', 10000000, 'Ini tugasnya manipulasi kerjaan', '2026-06-13 01:03:55.680663-07', '2026-06-13 03:21:46.457077-07');


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users VALUES ('SUPER-ADMIN-ID', 'SYSTEM', NULL, 'Super Admin', 'videntiiii@gmail.com', '$2a$14$ebxi7hb4pmi4SMYxWJYv1OJEwPuha8se7TznYlM1vS5aMVUn3I.qO', '', '', '', '', '', '', '', 'SUPER_ADMIN', 'ACTIVE', '', '', '', '', '', NULL, 0, NULL, '2026-06-13 00:22:37.879184-07', '2026-06-21 10:58:34.820221-07');
INSERT INTO public.users VALUES ('859f8da5-0ea0-4ed7-84b8-557878c134a2', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', '1e332dec-14d9-4516-923a-63f99c95fc71', 'Oktova Samosir', 'oktovaaaaa@gmail.com', '$2a$14$wYr8ipdaKhBN3lsqF/49wuaUiu3H4EjGloVpKNVmT076tMkoVmEqO', '$2a$10$jLexoAqU2V6iFYHBMIO4EezKnj5ErEeHtfHhxzLIsFtycj6jffOAW', '0881080811110', 'Kediri', '2000-01-18', 'Balige', '', '', 'ADMIN', 'ACTIVE', '', '', '', '', '', NULL, 0, NULL, '2026-06-13 03:44:02.63067-07', '2026-06-21 10:58:34.909827-07');
INSERT INTO public.users VALUES ('07458220-573e-4bff-a07e-407c8c6f2d5e', 'eaa1123a-b7fe-42e4-a94a-bafc55eaef95', 'bc8c7e38-0e7e-4304-a1f2-307a95ce0a03', 'Okoltova', 'okoltova@gmail.com', '$2a$14$xIm.I1pNft.SAI2XcE9lveNo9/JUFmQs1/TUkmsLcPYwP1D6zhFKK', '$2a$10$ZOh407xDkgeh6JWJWy.oEO2ojGaRO649.ASZx9aeOTCR9Rj/R38RC', '0881080811110', 'Balige', '2000-01-12', 'Balige', '', 'eOLJ0yBYRuOf2lYVersw2y:APA91bHW3onmGIeJw4IglWAphZIShTfX_7LvDSMKt2zvD_dpRSdmGtmlwaMkmwKqg5-RUIYocyiHwl872z1iw2mWzVFczsoPK2O9BZHj6sD3Sx-MennZQ1I', 'EMPLOYEE', 'ACTIVE', '', '1782061193997', 'Mandiri', '100110001', '[1.1207719,0.9126593,1.2098266,-0.5668856,-0.2703379,1.4556952,-0.8032554,-0.7509675,0.55196893,-0.21761677,0.18949585,0.15935937,-0.45563316,-0.21215408,-1.3440886,0.30266988,0.9202639,-0.22201088,0.9508314,-0.9438478,0.09134332,-2.2290332,0.8756779,0.9357548,-0.013222599,-0.9103936,-1.1052251,-0.700463,0.42169148,0.40565044,1.8049746,-0.3981052,-0.766935,-1.5567287,-0.06201334,-0.95096904,-0.16840644,0.59943324,-0.6247894,-1.3917499,0.48170575,-0.6453255,1.4200736,-0.0054976763,-0.94202363,0.91495407,0.5585769,0.9199332,0.017591571,0.45933628,2.0891356,0.77290255,0.2565899,0.749807,0.6541742,0.4061165,-0.5102259,-0.18873963,0.44966635,0.27033454,-0.020135213,0.70517564,0.3405925,0.70220524,0.88630646,-0.56560117,0.11216004,-0.845821,-0.5722488,-0.21965234,-1.1087811,-1.2639225,-0.06359477,-1.8693348,-2.312765,0.80740374,-0.6907581,-2.398169,2.870074,-0.1940062,-0.12495799,-1.234894,-0.03684609,0.4819758,-0.8168621,-0.30520028,0.16687915,-0.5321039,0.18061946,0.49307427,0.15783384,0.71388024,0.45478305,0.17604223,-0.3515219,1.235952,0.26846778,-0.9163332,-0.12697008,-0.14771947,0.6701703,0.118246555,0.29231542,0.45930535,0.24063635,0.12826692,-1.5397105,-1.8761089,-0.8695749,0.5943904,1.3084223,1.0048763,0.6483868,-0.8402544,-1.1792262,0.64597917,0.43342,-1.1993501,-0.925553,0.48678845,-0.80755126,0.50608796,-0.1887699,0.3033433,-0.19914007,0.6224171,-0.10708181,-0.7643081,0.3435232,1.1700939,2.2670949,0.37064153,-0.28491428,-0.42688957,-1.2782873,0.28478855,0.46919656,0.14542592,0.82071173,0.64823085,0.48666304,-0.3972944,-0.94275886,-1.3591901,-1.4004638,0.8162648,-0.30664793,0.25948432,0.4125704,0.7890534,-0.8761773,0.24367857,0.50243443,1.3057083,1.2643979,-0.48816624,-0.5771948,-2.308709,-0.14931624,1.0799654,0.9606632,0.82229596,-0.679313,0.11738219,0.5053931,1.3435733,-1.0791147,-1.0596172,-1.5984211,0.33363724,0.18401003,-1.5648706,0.20362219,1.8019425,0.9110284,0.8437298,-0.004124701,1.6549441,1.6650465,0.7419015,1.3880078,0.9398674,-0.8937828,0.071731515,-0.8357962,-0.58242875,0.17729104,-1.3263547,1.4275258,-0.8971488,-0.4447183,-0.05535195,1.8602422,0.7209047,-1.3553793,-1.7037399,-1.4680068,0.23481917,1.1956613,-0.3638088,0.40342623,-0.7441036,1.4806433,-0.87387514,2.6068337,0.82799846,1.2179253,-0.50465715,0.27389964,0.6254822,-1.673205,0.018896744,-0.42619458,-1.0674084,0.36609903,1.3061584,-0.3333846,-0.38010627,-1.5098455,0.70861024,2.5012517,1.2956057,-0.3657624,0.17413525,-0.56966174,-0.8689806,-1.3279027,-0.66187054,0.45246476,-0.7175317,-0.8627998,-1.279258,0.74225193,0.26343316,-1.2351115,-0.67269677,-2.267681,1.4140738,-1.3886913,-0.021134805,-0.004731131,-1.5963554,-1.1232865,-0.43035278,2.2516625,1.2590996,-0.06233375,-0.27593857,-0.9419466,-0.19287567,-0.10155477,0.4404307,0.3510055,0.20640893,1.006051,-1.0255171,-1.3715498,0.28879485,1.3032961,2.0152586,-0.47571453,-1.2232931,0.20138197,-0.41438237,0.9296352,-0.3620651,-0.22629333,0.370885,0.685338,-1.3865938,0.7968562,-0.34255573,0.55731755,0.563043,0.14021268,0.21942797,-0.50390816,0.5430641,2.150064,-0.14005224,-0.97987354,0.693881,0.68151253,-0.36511058,1.363597,-0.1902726,-0.5741547,-1.3980142,1.1508468,-0.6039119,0.9023787,0.458277,1.2562693,1.4327614,0.13872722,-0.87681836,-0.7074223,-0.640958,0.022049237,0.27018338,-0.4700424,-0.41286126,-0.73764884,2.0408008,0.30284867,0.5003173,-1.2449881,0.47049767,0.13998121,-0.2567188,0.41325435,0.3990062,-0.006187141,1.6621351,1.3808619,1.1087517,0.9795079,0.5854128,-0.15125644,-1.3111045,0.30463266,-3.1919866,-0.48630685,0.89397156,-1.1012194,0.70835525,-1.1495605,1.7949129,-0.66446555,0.2530052,-0.38633654,-1.2763433,-1.3831159,0.50690985,-0.55842817,0.113633774,-1.1969467,-0.8436182,0.4286674,1.222512,-0.563401,0.8129814,0.2814424,-1.7584345,-1.4905945,0.37057418,0.15519209,0.22425826,0.34624362,0.5307883,1.9075896,0.42349362,0.206392,-0.8894488,-0.94267815,-0.28119397,0.22779736,-0.40643635,0.36162603,-0.8104828,0.18994626,0.28215498,-0.86789787,0.052875064,0.580851,-0.9897763,0.3401986,-0.15573342,0.9103001,-0.38408,1.3754326,2.3464646,-1.231678,-1.2709213,0.6193847,0.48222333,-1.075134,0.012198359,0.42217198,-0.06779256,-1.4329469,-0.14978547,0.3833211,0.8609268,0.3146364,0.56150776,1.0764219,0.2514854,0.64610165,-0.8343561,-0.69405764,-0.7854825,0.17289396,0.72246045,0.5527665,1.6913815,-0.036836654,0.76910555,-0.88319033,-0.30991608,-0.45129877,-1.7076114,-0.11216613,0.44434348,-1.5158947,1.2583282,-0.6692414,0.5582768,-0.76357585,-0.13612981,-0.48821408,0.13026932,0.9371213,-1.1860845,0.89594316,0.33763522,0.5716299,-0.597984,0.33494806,-1.4116724,-0.22322007,0.5538207,-0.2792618,0.4198249,0.020191956,0.41294178,-1.011089,0.8225583,-0.88504916,0.8486352,-0.5665962,1.7815044,1.0800383,0.4473589,0.051748075,-0.9939704,-0.39654255,-0.12166347,-0.20743462,0.36696282,0.31313452,-0.41386333,-1.3152449,-0.5863405,-0.07797481,-1.0488069,0.07362262,0.25074813,1.0901706,0.5947198,-0.19010147,-0.79862744,-1.5502746,1.3697847,0.7271026,0.1411514,0.15721083,-2.7996423,-1.2956475,-0.23840931,-0.17198293,0.2373311,-0.6570356,0.9913052,1.3107898,0.94384634,-1.1432683,-0.32035705,-0.79981184,-0.9310873,0.16035691,-0.16875106,-0.64528114,0.82677066,-0.66442466,-1.2934912,2.1232784,-0.8219944,0.07957338,0.71331877,0.6134652,-0.86438835,1.1867185,0.23348503,-1.3878989,-0.16704121,0.93600166,2.1281419,2.0673325,-0.6085377,-0.6513777,-0.7100093,-1.2485359,0.6998446,-0.2604607,0.060066245,0.34634328,-0.38704178,0.51476747,1.0236061,-1.6058375,0.7604754,1.6348966,-0.07772335,-1.6561638,-0.6502997,0.5433016,-0.45344788,-0.7162412,0.12050954,0.46627226,0.22326283]', NULL, 0, NULL, '2026-02-28 09:00:00-08', '2026-06-21 10:58:35.103728-07');


--
-- Name: attendance_settings attendance_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_settings
    ADD CONSTRAINT attendance_settings_pkey PRIMARY KEY (id);


--
-- Name: attendances attendances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT attendances_pkey PRIMARY KEY (id);


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
-- Name: company_wifis company_wifis_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company_wifis
    ADD CONSTRAINT company_wifis_pkey PRIMARY KEY (id);


--
-- Name: holidays holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (id);


--
-- Name: leave_requests leave_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leave_requests
    ADD CONSTRAINT leave_requests_pkey PRIMARY KEY (id);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (id);


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
-- Name: idx_attendance_settings_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_attendance_settings_company_id ON public.attendance_settings USING btree (company_id);


--
-- Name: idx_attendances_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attendances_company_id ON public.attendances USING btree (company_id);


--
-- Name: idx_attendances_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attendances_user_id ON public.attendances USING btree (user_id);


--
-- Name: idx_company_locations_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_company_locations_company_id ON public.company_locations USING btree (company_id);


--
-- Name: idx_company_wifis_bss_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_company_wifis_bss_id ON public.company_wifis USING btree (bss_id);


--
-- Name: idx_company_wifis_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_company_wifis_company_id ON public.company_wifis USING btree (company_id);


--
-- Name: idx_company_wifis_location_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_company_wifis_location_id ON public.company_wifis USING btree (location_id);


--
-- Name: idx_holidays_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_holidays_company_id ON public.holidays USING btree (company_id);


--
-- Name: idx_leave_requests_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_leave_requests_company_id ON public.leave_requests USING btree (company_id);


--
-- Name: idx_leave_requests_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_leave_requests_user_id ON public.leave_requests USING btree (user_id);


--
-- Name: idx_positions_company_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_positions_company_id ON public.positions USING btree (company_id);


--
-- Name: attendance_settings fk_attendance_settings_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance_settings
    ADD CONSTRAINT fk_attendance_settings_company FOREIGN KEY (company_id) REFERENCES public.companies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: attendances fk_attendances_check_in_location; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT fk_attendances_check_in_location FOREIGN KEY (check_in_location_id) REFERENCES public.company_locations(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: attendances fk_attendances_check_out_location; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT fk_attendances_check_out_location FOREIGN KEY (check_out_location_id) REFERENCES public.company_locations(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: attendances fk_attendances_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT fk_attendances_company FOREIGN KEY (company_id) REFERENCES public.companies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: attendances fk_attendances_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT fk_attendances_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: company_locations fk_company_locations_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company_locations
    ADD CONSTRAINT fk_company_locations_company FOREIGN KEY (company_id) REFERENCES public.companies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: company_wifis fk_company_wifis_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company_wifis
    ADD CONSTRAINT fk_company_wifis_company FOREIGN KEY (company_id) REFERENCES public.companies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: company_wifis fk_company_wifis_location; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company_wifis
    ADD CONSTRAINT fk_company_wifis_location FOREIGN KEY (location_id) REFERENCES public.company_locations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: holidays fk_holidays_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT fk_holidays_company FOREIGN KEY (company_id) REFERENCES public.companies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: leave_requests fk_leave_requests_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leave_requests
    ADD CONSTRAINT fk_leave_requests_company FOREIGN KEY (company_id) REFERENCES public.companies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: leave_requests fk_leave_requests_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leave_requests
    ADD CONSTRAINT fk_leave_requests_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: positions fk_positions_company; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT fk_positions_company FOREIGN KEY (company_id) REFERENCES public.companies(id) ON UPDATE CASCADE ON DELETE CASCADE;


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

