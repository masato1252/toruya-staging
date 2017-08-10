--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: access_providers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE access_providers (
    id integer NOT NULL,
    access_token character varying,
    refresh_token character varying,
    provider character varying,
    uid character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    email character varying
);


--
-- Name: access_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE access_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE access_providers_id_seq OWNED BY access_providers.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: business_schedules; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE business_schedules (
    id integer NOT NULL,
    shop_id integer,
    staff_id integer,
    full_time boolean,
    business_state character varying,
    day_of_week integer,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: business_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE business_schedules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: business_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE business_schedules_id_seq OWNED BY business_schedules.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE categories (
    id integer NOT NULL,
    user_id integer,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE categories_id_seq OWNED BY categories.id;


--
-- Name: contact_group_rankings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contact_group_rankings (
    id integer NOT NULL,
    contact_group_id integer,
    rank_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: contact_group_rankings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contact_group_rankings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contact_group_rankings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contact_group_rankings_id_seq OWNED BY contact_group_rankings.id;


--
-- Name: contact_groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contact_groups (
    id integer NOT NULL,
    user_id integer NOT NULL,
    google_uid character varying,
    google_group_name character varying,
    google_group_id character varying,
    backup_google_group_id character varying,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: contact_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contact_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contact_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contact_groups_id_seq OWNED BY contact_groups.id;


--
-- Name: custom_schedules; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE custom_schedules (
    id integer NOT NULL,
    shop_id integer,
    staff_id integer,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    reason text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    open boolean DEFAULT false NOT NULL
);


--
-- Name: custom_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE custom_schedules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE custom_schedules_id_seq OWNED BY custom_schedules.id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE customers (
    id integer NOT NULL,
    user_id integer NOT NULL,
    contact_group_id integer,
    rank_id integer,
    last_name character varying,
    first_name character varying,
    phonetic_last_name character varying,
    phonetic_first_name character varying,
    custom_id character varying,
    memo text,
    address character varying,
    google_uid character varying,
    google_contact_id character varying,
    google_contact_group_ids character varying[] DEFAULT '{}'::character varying[],
    birthday date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by_user_id integer,
    email_types character varying
);


--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE customers_id_seq OWNED BY customers.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    queue character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: menu_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE menu_categories (
    id integer NOT NULL,
    menu_id integer,
    category_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: menu_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE menu_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE menu_categories_id_seq OWNED BY menu_categories.id;


--
-- Name: menu_reservation_setting_rules; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE menu_reservation_setting_rules (
    id integer NOT NULL,
    menu_id integer,
    reservation_type character varying,
    start_date date,
    end_date date,
    repeats integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: menu_reservation_setting_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE menu_reservation_setting_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_reservation_setting_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE menu_reservation_setting_rules_id_seq OWNED BY menu_reservation_setting_rules.id;


--
-- Name: menus; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE menus (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying NOT NULL,
    short_name character varying,
    minutes integer,
    "interval" integer,
    min_staffs_number integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE menus_id_seq OWNED BY menus.id;


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE profiles (
    id integer NOT NULL,
    user_id integer,
    first_name character varying,
    last_name character varying,
    phonetic_first_name character varying,
    phonetic_last_name character varying,
    company_name character varying,
    zip_code character varying,
    address character varying,
    phone_number character varying,
    website character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE profiles_id_seq OWNED BY profiles.id;


--
-- Name: ranks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ranks (
    id integer NOT NULL,
    user_id integer,
    name character varying NOT NULL,
    key character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ranks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ranks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ranks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ranks_id_seq OWNED BY ranks.id;


--
-- Name: reservation_customers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reservation_customers (
    id integer NOT NULL,
    reservation_id integer NOT NULL,
    customer_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: reservation_customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reservation_customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservation_customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reservation_customers_id_seq OWNED BY reservation_customers.id;


--
-- Name: reservation_menus; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reservation_menus (
    id integer NOT NULL,
    reservation_id integer,
    menu_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: reservation_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reservation_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservation_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reservation_menus_id_seq OWNED BY reservation_menus.id;


--
-- Name: reservation_setting_menus; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reservation_setting_menus (
    id integer NOT NULL,
    reservation_setting_id integer,
    menu_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: reservation_setting_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reservation_setting_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservation_setting_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reservation_setting_menus_id_seq OWNED BY reservation_setting_menus.id;


--
-- Name: reservation_settings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reservation_settings (
    id integer NOT NULL,
    user_id integer,
    name character varying,
    short_name character varying,
    day_type character varying,
    day integer,
    nth_of_week integer,
    days_of_week character varying[] DEFAULT '{}'::character varying[],
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: reservation_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reservation_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservation_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reservation_settings_id_seq OWNED BY reservation_settings.id;


--
-- Name: reservation_staffs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reservation_staffs (
    id integer NOT NULL,
    reservation_id integer NOT NULL,
    staff_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: reservation_staffs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reservation_staffs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservation_staffs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reservation_staffs_id_seq OWNED BY reservation_staffs.id;


--
-- Name: reservations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reservations (
    id integer NOT NULL,
    shop_id integer NOT NULL,
    menu_id integer NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    ready_time timestamp without time zone NOT NULL,
    aasm_state character varying NOT NULL,
    memo text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    count_of_customers integer DEFAULT 0,
    with_warnings boolean DEFAULT false NOT NULL
);


--
-- Name: reservations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reservations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reservations_id_seq OWNED BY reservations.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: shop_menu_repeating_dates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE shop_menu_repeating_dates (
    id integer NOT NULL,
    shop_id integer NOT NULL,
    menu_id integer NOT NULL,
    dates character varying[] DEFAULT '{}'::character varying[],
    end_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: shop_menu_repeating_dates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE shop_menu_repeating_dates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shop_menu_repeating_dates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE shop_menu_repeating_dates_id_seq OWNED BY shop_menu_repeating_dates.id;


--
-- Name: shop_menus; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE shop_menus (
    id integer NOT NULL,
    shop_id integer,
    menu_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    max_seat_number integer
);


--
-- Name: shop_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE shop_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shop_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE shop_menus_id_seq OWNED BY shop_menus.id;


--
-- Name: shop_staffs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE shop_staffs (
    id integer NOT NULL,
    shop_id integer,
    staff_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    staff_regular_working_day_permission boolean DEFAULT false NOT NULL,
    staff_temporary_working_day_permission boolean DEFAULT false NOT NULL
);


--
-- Name: shop_staffs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE shop_staffs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shop_staffs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE shop_staffs_id_seq OWNED BY shop_staffs.id;


--
-- Name: shops; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE shops (
    id integer NOT NULL,
    user_id integer,
    name character varying NOT NULL,
    short_name character varying NOT NULL,
    zip_code character varying NOT NULL,
    phone_number character varying NOT NULL,
    email character varying NOT NULL,
    address character varying NOT NULL,
    website character varying,
    holiday_working boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: shops_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE shops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE shops_id_seq OWNED BY shops.id;


--
-- Name: staff_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE staff_accounts (
    id integer NOT NULL,
    email character varying NOT NULL,
    user_id integer,
    owner_id integer NOT NULL,
    staff_id integer NOT NULL,
    token character varying,
    state integer DEFAULT 0 NOT NULL,
    level integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: staff_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE staff_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE staff_accounts_id_seq OWNED BY staff_accounts.id;


--
-- Name: staff_menus; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE staff_menus (
    id integer NOT NULL,
    staff_id integer NOT NULL,
    menu_id integer NOT NULL,
    max_customers integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: staff_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE staff_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE staff_menus_id_seq OWNED BY staff_menus.id;


--
-- Name: staffs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE staffs (
    id integer NOT NULL,
    user_id integer NOT NULL,
    last_name character varying,
    first_name character varying,
    phonetic_last_name character varying,
    phonetic_first_name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    staff_holiday_permission boolean DEFAULT false NOT NULL
);


--
-- Name: staffs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE staffs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staffs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE staffs_id_seq OWNED BY staffs.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    level integer DEFAULT 0 NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_providers ALTER COLUMN id SET DEFAULT nextval('access_providers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY business_schedules ALTER COLUMN id SET DEFAULT nextval('business_schedules_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY categories ALTER COLUMN id SET DEFAULT nextval('categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contact_group_rankings ALTER COLUMN id SET DEFAULT nextval('contact_group_rankings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contact_groups ALTER COLUMN id SET DEFAULT nextval('contact_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_schedules ALTER COLUMN id SET DEFAULT nextval('custom_schedules_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY customers ALTER COLUMN id SET DEFAULT nextval('customers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY menu_categories ALTER COLUMN id SET DEFAULT nextval('menu_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY menu_reservation_setting_rules ALTER COLUMN id SET DEFAULT nextval('menu_reservation_setting_rules_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY menus ALTER COLUMN id SET DEFAULT nextval('menus_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY profiles ALTER COLUMN id SET DEFAULT nextval('profiles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY ranks ALTER COLUMN id SET DEFAULT nextval('ranks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reservation_customers ALTER COLUMN id SET DEFAULT nextval('reservation_customers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reservation_menus ALTER COLUMN id SET DEFAULT nextval('reservation_menus_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reservation_setting_menus ALTER COLUMN id SET DEFAULT nextval('reservation_setting_menus_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reservation_settings ALTER COLUMN id SET DEFAULT nextval('reservation_settings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reservation_staffs ALTER COLUMN id SET DEFAULT nextval('reservation_staffs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reservations ALTER COLUMN id SET DEFAULT nextval('reservations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY shop_menu_repeating_dates ALTER COLUMN id SET DEFAULT nextval('shop_menu_repeating_dates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY shop_menus ALTER COLUMN id SET DEFAULT nextval('shop_menus_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY shop_staffs ALTER COLUMN id SET DEFAULT nextval('shop_staffs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY shops ALTER COLUMN id SET DEFAULT nextval('shops_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY staff_accounts ALTER COLUMN id SET DEFAULT nextval('staff_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY staff_menus ALTER COLUMN id SET DEFAULT nextval('staff_menus_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY staffs ALTER COLUMN id SET DEFAULT nextval('staffs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: access_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY access_providers
    ADD CONSTRAINT access_providers_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: business_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY business_schedules
    ADD CONSTRAINT business_schedules_pkey PRIMARY KEY (id);


--
-- Name: categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: contact_group_rankings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contact_group_rankings
    ADD CONSTRAINT contact_group_rankings_pkey PRIMARY KEY (id);


--
-- Name: contact_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contact_groups
    ADD CONSTRAINT contact_groups_pkey PRIMARY KEY (id);


--
-- Name: custom_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY custom_schedules
    ADD CONSTRAINT custom_schedules_pkey PRIMARY KEY (id);


--
-- Name: customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: menu_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY menu_categories
    ADD CONSTRAINT menu_categories_pkey PRIMARY KEY (id);


--
-- Name: menu_reservation_setting_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY menu_reservation_setting_rules
    ADD CONSTRAINT menu_reservation_setting_rules_pkey PRIMARY KEY (id);


--
-- Name: menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY menus
    ADD CONSTRAINT menus_pkey PRIMARY KEY (id);


--
-- Name: profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: ranks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ranks
    ADD CONSTRAINT ranks_pkey PRIMARY KEY (id);


--
-- Name: reservation_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reservation_customers
    ADD CONSTRAINT reservation_customers_pkey PRIMARY KEY (id);


--
-- Name: reservation_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reservation_menus
    ADD CONSTRAINT reservation_menus_pkey PRIMARY KEY (id);


--
-- Name: reservation_setting_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reservation_setting_menus
    ADD CONSTRAINT reservation_setting_menus_pkey PRIMARY KEY (id);


--
-- Name: reservation_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reservation_settings
    ADD CONSTRAINT reservation_settings_pkey PRIMARY KEY (id);


--
-- Name: reservation_staffs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reservation_staffs
    ADD CONSTRAINT reservation_staffs_pkey PRIMARY KEY (id);


--
-- Name: reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: shop_menu_repeating_dates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY shop_menu_repeating_dates
    ADD CONSTRAINT shop_menu_repeating_dates_pkey PRIMARY KEY (id);


--
-- Name: shop_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY shop_menus
    ADD CONSTRAINT shop_menus_pkey PRIMARY KEY (id);


--
-- Name: shop_staffs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY shop_staffs
    ADD CONSTRAINT shop_staffs_pkey PRIMARY KEY (id);


--
-- Name: shops_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY shops
    ADD CONSTRAINT shops_pkey PRIMARY KEY (id);


--
-- Name: staff_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY staff_accounts
    ADD CONSTRAINT staff_accounts_pkey PRIMARY KEY (id);


--
-- Name: staff_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY staff_menus
    ADD CONSTRAINT staff_menus_pkey PRIMARY KEY (id);


--
-- Name: staffs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY staffs
    ADD CONSTRAINT staffs_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: contact_groups_google_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX contact_groups_google_index ON contact_groups USING btree (user_id, google_uid, google_group_id, backup_google_group_id);


--
-- Name: customer_names_on_first_name_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX customer_names_on_first_name_idx ON customers USING gin (first_name gin_trgm_ops);


--
-- Name: customer_names_on_last_name_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX customer_names_on_last_name_idx ON customers USING gin (last_name gin_trgm_ops);


--
-- Name: customer_names_on_phonetic_first_name_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX customer_names_on_phonetic_first_name_idx ON customers USING gin (phonetic_first_name gin_trgm_ops);


--
-- Name: customer_names_on_phonetic_last_name_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX customer_names_on_phonetic_last_name_idx ON customers USING gin (phonetic_last_name gin_trgm_ops);


--
-- Name: customers_google_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX customers_google_index ON customers USING btree (user_id, google_uid, google_contact_id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX delayed_jobs_priority ON delayed_jobs USING btree (priority, run_at);


--
-- Name: index_access_providers_on_provider_and_uid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_access_providers_on_provider_and_uid ON access_providers USING btree (provider, uid);


--
-- Name: index_categories_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_categories_on_user_id ON categories USING btree (user_id);


--
-- Name: index_contact_group_rankings_on_contact_group_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contact_group_rankings_on_contact_group_id ON contact_group_rankings USING btree (contact_group_id);


--
-- Name: index_contact_group_rankings_on_rank_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contact_group_rankings_on_rank_id ON contact_group_rankings USING btree (rank_id);


--
-- Name: index_contact_groups_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contact_groups_on_user_id ON contact_groups USING btree (user_id);


--
-- Name: index_custom_schedules_on_staff_id_and_open; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_custom_schedules_on_staff_id_and_open ON custom_schedules USING btree (staff_id, open);


--
-- Name: index_customers_on_contact_group_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_customers_on_contact_group_id ON customers USING btree (contact_group_id);


--
-- Name: index_customers_on_rank_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_customers_on_rank_id ON customers USING btree (rank_id);


--
-- Name: index_customers_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_customers_on_user_id ON customers USING btree (user_id);


--
-- Name: index_menu_categories_on_menu_id_and_category_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_menu_categories_on_menu_id_and_category_id ON menu_categories USING btree (menu_id, category_id);


--
-- Name: index_menus_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_menus_on_user_id ON menus USING btree (user_id);


--
-- Name: index_profiles_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_profiles_on_user_id ON profiles USING btree (user_id);


--
-- Name: index_ranks_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_ranks_on_user_id ON ranks USING btree (user_id);


--
-- Name: index_reservation_customers_on_reservation_id_and_customer_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_reservation_customers_on_reservation_id_and_customer_id ON reservation_customers USING btree (reservation_id, customer_id);


--
-- Name: index_reservation_staffs_on_reservation_id_and_staff_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_reservation_staffs_on_reservation_id_and_staff_id ON reservation_staffs USING btree (reservation_id, staff_id);


--
-- Name: index_shop_menu_repeating_dates_on_menu_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_shop_menu_repeating_dates_on_menu_id ON shop_menu_repeating_dates USING btree (menu_id);


--
-- Name: index_shop_menu_repeating_dates_on_shop_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_shop_menu_repeating_dates_on_shop_id ON shop_menu_repeating_dates USING btree (shop_id);


--
-- Name: index_shop_menu_repeating_dates_on_shop_id_and_menu_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_shop_menu_repeating_dates_on_shop_id_and_menu_id ON shop_menu_repeating_dates USING btree (shop_id, menu_id);


--
-- Name: index_shop_menus_on_shop_id_and_menu_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_shop_menus_on_shop_id_and_menu_id ON shop_menus USING btree (shop_id, menu_id);


--
-- Name: index_shop_staffs_on_shop_id_and_staff_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_shop_staffs_on_shop_id_and_staff_id ON shop_staffs USING btree (shop_id, staff_id);


--
-- Name: index_shops_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_shops_on_user_id ON shops USING btree (user_id);


--
-- Name: index_staff_accounts_on_owner_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_staff_accounts_on_owner_id ON staff_accounts USING btree (owner_id);


--
-- Name: index_staff_accounts_on_staff_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_staff_accounts_on_staff_id ON staff_accounts USING btree (staff_id);


--
-- Name: index_staff_accounts_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_staff_accounts_on_user_id ON staff_accounts USING btree (user_id);


--
-- Name: index_staff_menus_on_staff_id_and_menu_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_staff_menus_on_staff_id_and_menu_id ON staff_menus USING btree (staff_id, menu_id);


--
-- Name: index_staffs_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_staffs_on_user_id ON staffs USING btree (user_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON users USING btree (unlock_token);


--
-- Name: jp_name_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX jp_name_index ON customers USING btree (user_id, phonetic_last_name, phonetic_first_name);


--
-- Name: menu_reservation_setting_rules_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX menu_reservation_setting_rules_index ON menu_reservation_setting_rules USING btree (menu_id, reservation_type, start_date, end_date);


--
-- Name: reservation_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX reservation_index ON reservations USING btree (shop_id, aasm_state, menu_id, start_time, ready_time);


--
-- Name: reservation_setting_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX reservation_setting_index ON reservation_settings USING btree (user_id, start_time, end_time, day_type, days_of_week, day, nth_of_week);


--
-- Name: reservation_setting_menus_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX reservation_setting_menus_index ON reservation_setting_menus USING btree (reservation_setting_id, menu_id);


--
-- Name: shop_custom_schedules_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX shop_custom_schedules_index ON custom_schedules USING btree (shop_id, start_time, end_time);


--
-- Name: shop_working_time_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX shop_working_time_index ON business_schedules USING btree (shop_id, business_state, day_of_week, start_time, end_time);


--
-- Name: staff_account_email_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX staff_account_email_index ON staff_accounts USING btree (owner_id, email);


--
-- Name: staff_account_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX staff_account_index ON staff_accounts USING btree (owner_id, user_id);


--
-- Name: staff_account_token_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX staff_account_token_index ON staff_accounts USING btree (token);


--
-- Name: staff_custom_schedules_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX staff_custom_schedules_index ON custom_schedules USING btree (staff_id, start_time, end_time);


--
-- Name: staff_working_time_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX staff_working_time_index ON business_schedules USING btree (shop_id, staff_id, full_time, business_state, day_of_week, start_time, end_time);


--
-- Name: fk_rails_e424190865; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY profiles
    ADD CONSTRAINT fk_rails_e424190865 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20160705120808'), ('20160705141152'), ('20160708021248'), ('20160708044201'), ('20160708081126'), ('20160711124845'), ('20160713083223'), ('20160716040038'), ('20160803123550'), ('20160804141647'), ('20160805002152'), ('20160810123145'), ('20160810124115'), ('20160830151522'), ('20160830235902'), ('20160908135552'), ('20160908140827'), ('20160912071828'), ('20160912094849'), ('20160924015503'), ('20161018154942'), ('20161024135214'), ('20161027141005'), ('20161027234643'), ('20161116133354'), ('20161211160502'), ('20161218061913'), ('20161226152244'), ('20170101060554'), ('20170101060841'), ('20170117143626'), ('20170122022230'), ('20170411092212'), ('20170509132433'), ('20170513074508'), ('20170530085552'), ('20170611060236'), ('20170611073611'), ('20170627082223'), ('20170720142102');
