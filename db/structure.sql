\restrict famd8XepDBKW7QAzVfxqGUuLmYVKkiEwpKHQlgJZwDTL6ctwYrawjN7X3DO4kBF

-- Dumped from database version 16.10
-- Dumped by pg_dump version 18.0

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

--
-- Name: _heroku; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA _heroku;


--
-- Name: heroku_ext; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA heroku_ext;


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: btree_gin; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;


--
-- Name: EXTENSION btree_gin; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gin IS 'support for indexing common datatypes in GIN';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: create_ext(); Type: FUNCTION; Schema: _heroku; Owner: -
--

CREATE FUNCTION _heroku.create_ext() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  schemaname TEXT;
  databaseowner TEXT;

  r RECORD;

BEGIN

  IF tg_tag OPERATOR(pg_catalog.=) 'CREATE EXTENSION' AND current_user OPERATOR(pg_catalog.!=) 'rds_superuser' THEN
    PERFORM _heroku.validate_search_path();

    FOR r IN SELECT * FROM pg_catalog.pg_event_trigger_ddl_commands()
    LOOP
        CONTINUE WHEN r.command_tag != 'CREATE EXTENSION' OR r.object_type != 'extension';

        schemaname := (
            SELECT n.nspname
            FROM pg_catalog.pg_extension AS e
            INNER JOIN pg_catalog.pg_namespace AS n
            ON e.extnamespace = n.oid
            WHERE e.oid = r.objid
        );

        databaseowner := (
            SELECT pg_catalog.pg_get_userbyid(d.datdba)
            FROM pg_catalog.pg_database d
            WHERE d.datname = pg_catalog.current_database()
        );
        --RAISE NOTICE 'Record for event trigger %, objid: %,tag: %, current_user: %, schema: %, database_owenr: %', r.object_identity, r.objid, tg_tag, current_user, schemaname, databaseowner;
        IF r.object_identity = 'address_standardizer_data_us' THEN
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'us_gaz');
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'us_lex');
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'us_rules');
        ELSIF r.object_identity = 'amcheck' THEN
            EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %I.bt_index_check TO %I;', schemaname, databaseowner);
            EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %I.bt_index_parent_check TO %I;', schemaname, databaseowner);
        ELSIF r.object_identity = 'dict_int' THEN
            EXECUTE pg_catalog.format('ALTER TEXT SEARCH DICTIONARY %I.intdict OWNER TO %I;', schemaname, databaseowner);
        ELSIF r.object_identity = 'pg_partman' THEN
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'part_config');
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'part_config_sub');
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT, UPDATE, INSERT, DELETE', databaseowner, 'custom_time_partitions');
        ELSIF r.object_identity = 'pg_stat_statements' THEN
            EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %I.pg_stat_statements_reset TO %I;', schemaname, databaseowner);
        ELSIF r.object_identity = 'postgis' THEN
            PERFORM _heroku.postgis_after_create();
        ELSIF r.object_identity = 'postgis_raster' THEN
            PERFORM _heroku.postgis_after_create();
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT', databaseowner, 'raster_columns');
            PERFORM _heroku.grant_table_if_exists(schemaname, 'SELECT', databaseowner, 'raster_overviews');
        ELSIF r.object_identity = 'postgis_topology' THEN
            PERFORM _heroku.postgis_after_create();
            EXECUTE pg_catalog.format('GRANT USAGE ON SCHEMA topology TO %I;', databaseowner);
            EXECUTE pg_catalog.format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA topology TO %I;', databaseowner);
            PERFORM _heroku.grant_table_if_exists('topology', 'SELECT, UPDATE, INSERT, DELETE', databaseowner);
            EXECUTE pg_catalog.format('GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA topology TO %I;', databaseowner);
        ELSIF r.object_identity = 'postgis_tiger_geocoder' THEN
            PERFORM _heroku.postgis_after_create();
            EXECUTE pg_catalog.format('GRANT USAGE ON SCHEMA tiger TO %I;', databaseowner);
            EXECUTE pg_catalog.format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA tiger TO %I;', databaseowner);
            PERFORM _heroku.grant_table_if_exists('tiger', 'SELECT, UPDATE, INSERT, DELETE', databaseowner);

            EXECUTE pg_catalog.format('GRANT USAGE ON SCHEMA tiger_data TO %I;', databaseowner);
            EXECUTE pg_catalog.format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA tiger_data TO %I;', databaseowner);
            PERFORM _heroku.grant_table_if_exists('tiger_data', 'SELECT, UPDATE, INSERT, DELETE', databaseowner);
        END IF;
    END LOOP;
  END IF;
END;
$$;


--
-- Name: drop_ext(); Type: FUNCTION; Schema: _heroku; Owner: -
--

CREATE FUNCTION _heroku.drop_ext() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  schemaname TEXT;
  databaseowner TEXT;

  r RECORD;

BEGIN

  IF tg_tag OPERATOR(pg_catalog.=) 'DROP EXTENSION' AND current_user OPERATOR(pg_catalog.!=) 'rds_superuser' THEN
    PERFORM _heroku.validate_search_path();

    FOR r IN SELECT * FROM pg_catalog.pg_event_trigger_dropped_objects()
    LOOP
      CONTINUE WHEN r.object_type != 'extension';

      databaseowner := (
            SELECT pg_catalog.pg_get_userbyid(d.datdba)
            FROM pg_catalog.pg_database d
            WHERE d.datname = pg_catalog.current_database()
      );

      --RAISE NOTICE 'Record for event trigger %, objid: %,tag: %, current_user: %, database_owner: %, schemaname: %', r.object_identity, r.objid, tg_tag, current_user, databaseowner, r.schema_name;

      IF r.object_identity = 'postgis_topology' THEN
          EXECUTE pg_catalog.format('DROP SCHEMA IF EXISTS topology');
      END IF;
    END LOOP;

  END IF;
END;
$$;


--
-- Name: extension_before_drop(); Type: FUNCTION; Schema: _heroku; Owner: -
--

CREATE FUNCTION _heroku.extension_before_drop() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  query TEXT;

BEGIN
  query := (SELECT pg_catalog.current_query());

  -- RAISE NOTICE 'executing extension_before_drop: tg_event: %, tg_tag: %, current_user: %, session_user: %, query: %', tg_event, tg_tag, current_user, session_user, query;
  IF tg_tag OPERATOR(pg_catalog.=) 'DROP EXTENSION' AND NOT pg_catalog.pg_has_role(session_user, 'rds_superuser', 'MEMBER') THEN
    PERFORM _heroku.validate_search_path();

    -- DROP EXTENSION [ IF EXISTS ] name [, ...] [ CASCADE | RESTRICT ]
    IF (pg_catalog.regexp_match(query, 'DROP\s+EXTENSION\s+(IF\s+EXISTS)?.*(plpgsql)', 'i') IS NOT NULL) THEN
      RAISE EXCEPTION 'The plpgsql extension is required for database management and cannot be dropped.';
    END IF;
  END IF;
END;
$$;


--
-- Name: grant_table_if_exists(text, text, text, text); Type: FUNCTION; Schema: _heroku; Owner: -
--

CREATE FUNCTION _heroku.grant_table_if_exists(alias_schemaname text, grants text, databaseowner text, alias_tablename text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

BEGIN
  PERFORM _heroku.validate_search_path();

  IF alias_tablename IS NULL THEN
    EXECUTE pg_catalog.format('GRANT %s ON ALL TABLES IN SCHEMA %I TO %I;', grants, alias_schemaname, databaseowner);
  ELSE
    IF EXISTS (SELECT 1 FROM pg_tables WHERE pg_tables.schemaname = alias_schemaname AND pg_tables.tablename = alias_tablename) THEN
      EXECUTE pg_catalog.format('GRANT %s ON TABLE %I.%I TO %I;', grants, alias_schemaname, alias_tablename, databaseowner);
    END IF;
  END IF;
END;
$$;


--
-- Name: postgis_after_create(); Type: FUNCTION; Schema: _heroku; Owner: -
--

CREATE FUNCTION _heroku.postgis_after_create() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    schemaname TEXT;
    databaseowner TEXT;
BEGIN
    PERFORM _heroku.validate_search_path();

    schemaname := (
        SELECT n.nspname
        FROM pg_catalog.pg_extension AS e
        INNER JOIN pg_catalog.pg_namespace AS n ON e.extnamespace = n.oid
        WHERE e.extname = 'postgis'
    );
    databaseowner := (
        SELECT pg_catalog.pg_get_userbyid(d.datdba)
        FROM pg_catalog.pg_database d
        WHERE d.datname = pg_catalog.current_database()
    );

    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %I.st_tileenvelope TO %I;', schemaname, databaseowner);
    EXECUTE pg_catalog.format('GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE %I.spatial_ref_sys TO %I;', schemaname, databaseowner);
END;
$$;


--
-- Name: validate_extension(); Type: FUNCTION; Schema: _heroku; Owner: -
--

CREATE FUNCTION _heroku.validate_extension() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  schemaname TEXT;
  r RECORD;

BEGIN

  IF tg_tag OPERATOR(pg_catalog.=) 'CREATE EXTENSION' AND current_user OPERATOR(pg_catalog.!=) 'rds_superuser' THEN
    PERFORM _heroku.validate_search_path();

    FOR r IN SELECT * FROM pg_catalog.pg_event_trigger_ddl_commands()
    LOOP
      CONTINUE WHEN r.command_tag != 'CREATE EXTENSION' OR r.object_type != 'extension';

      schemaname := (
        SELECT n.nspname
        FROM pg_catalog.pg_extension AS e
        INNER JOIN pg_catalog.pg_namespace AS n
        ON e.extnamespace = n.oid
        WHERE e.oid = r.objid
      );

      IF schemaname = '_heroku' THEN
        RAISE EXCEPTION 'Creating extensions in the _heroku schema is not allowed';
      END IF;
    END LOOP;
  END IF;
END;
$$;


--
-- Name: validate_search_path(); Type: FUNCTION; Schema: _heroku; Owner: -
--

CREATE FUNCTION _heroku.validate_search_path() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE

  current_search_path TEXT;
  schemas TEXT[];
  pg_catalog_index INTEGER;

BEGIN

  current_search_path := pg_catalog.current_setting('search_path');
  schemas := pg_catalog.string_to_array(current_search_path, ',');

  schemas := (
    SELECT pg_catalog.array_agg(TRIM(schema_name::text))
    FROM pg_catalog.unnest(schemas) AS schema_name
  );

  IF ('pg_catalog' OPERATOR(pg_catalog.=) ANY(schemas)) THEN
    SELECT pg_catalog.array_position(schemas, 'pg_catalog') INTO pg_catalog_index;
    IF pg_catalog_index OPERATOR(pg_catalog.!=) 1 THEN
      RAISE EXCEPTION 'pg_catalog must be first in the search_path for this operation. Current search_path: %', current_search_path;
    END IF;
  END IF;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: access_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.access_providers (
    id integer NOT NULL,
    access_token character varying,
    refresh_token character varying,
    provider character varying,
    uid character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    email character varying,
    publishable_key character varying,
    default_payment boolean DEFAULT false
);


--
-- Name: access_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.access_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.access_providers_id_seq OWNED BY public.access_providers.id;


--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    byte_size bigint NOT NULL,
    checksum character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    service_name character varying NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ahoy_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ahoy_events (
    id bigint NOT NULL,
    visit_id bigint,
    user_id bigint,
    name character varying,
    properties jsonb,
    "time" timestamp without time zone
);


--
-- Name: ahoy_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ahoy_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ahoy_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ahoy_events_id_seq OWNED BY public.ahoy_events.id;


--
-- Name: ahoy_visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ahoy_visits (
    id bigint NOT NULL,
    visit_token character varying,
    visitor_token character varying,
    user_id bigint,
    ip character varying,
    user_agent text,
    referrer text,
    referring_domain character varying,
    landing_page text,
    browser character varying,
    os character varying,
    device_type character varying,
    country character varying,
    region character varying,
    city character varying,
    latitude double precision,
    longitude double precision,
    utm_source character varying,
    utm_medium character varying,
    utm_term character varying,
    utm_content character varying,
    utm_campaign character varying,
    app_version character varying,
    os_version character varying,
    platform character varying,
    started_at timestamp without time zone,
    customer_social_user_id character varying,
    owner_id character varying,
    product_id integer,
    product_type character varying
);


--
-- Name: ahoy_visits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ahoy_visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ahoy_visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ahoy_visits_id_seq OWNED BY public.ahoy_visits.id;


--
-- Name: ai_faqs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_faqs (
    id bigint NOT NULL,
    user_id character varying,
    question text,
    answer text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ai_faqs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_faqs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_faqs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ai_faqs_id_seq OWNED BY public.ai_faqs.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: blazer_audits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blazer_audits (
    id bigint NOT NULL,
    user_id bigint,
    query_id bigint,
    statement text,
    data_source character varying,
    created_at timestamp without time zone
);


--
-- Name: blazer_audits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blazer_audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blazer_audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blazer_audits_id_seq OWNED BY public.blazer_audits.id;


--
-- Name: blazer_checks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blazer_checks (
    id bigint NOT NULL,
    creator_id bigint,
    query_id bigint,
    state character varying,
    schedule character varying,
    emails text,
    slack_channels text,
    check_type character varying,
    message text,
    last_run_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: blazer_checks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blazer_checks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blazer_checks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blazer_checks_id_seq OWNED BY public.blazer_checks.id;


--
-- Name: blazer_dashboard_queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blazer_dashboard_queries (
    id bigint NOT NULL,
    dashboard_id bigint,
    query_id bigint,
    "position" integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: blazer_dashboard_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blazer_dashboard_queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blazer_dashboard_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blazer_dashboard_queries_id_seq OWNED BY public.blazer_dashboard_queries.id;


--
-- Name: blazer_dashboards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blazer_dashboards (
    id bigint NOT NULL,
    creator_id bigint,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: blazer_dashboards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blazer_dashboards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blazer_dashboards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blazer_dashboards_id_seq OWNED BY public.blazer_dashboards.id;


--
-- Name: blazer_queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blazer_queries (
    id bigint NOT NULL,
    creator_id bigint,
    name character varying,
    description text,
    statement text,
    data_source character varying,
    status character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: blazer_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blazer_queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blazer_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blazer_queries_id_seq OWNED BY public.blazer_queries.id;


--
-- Name: booking_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_codes (
    id bigint NOT NULL,
    uuid character varying,
    code character varying,
    booking_page_id integer,
    customer_id integer,
    reservation_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    phone_number character varying
);


--
-- Name: booking_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_codes_id_seq OWNED BY public.booking_codes.id;


--
-- Name: booking_option_menus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_option_menus (
    id bigint NOT NULL,
    booking_option_id bigint NOT NULL,
    menu_id bigint NOT NULL,
    priority integer,
    required_time integer
);


--
-- Name: booking_option_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_option_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_option_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_option_menus_id_seq OWNED BY public.booking_option_menus.id;


--
-- Name: booking_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_options (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    name character varying NOT NULL,
    display_name character varying,
    minutes integer NOT NULL,
    amount_cents numeric NOT NULL,
    amount_currency character varying NOT NULL,
    tax_include boolean NOT NULL,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    memo text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    menu_restrict_order boolean DEFAULT false NOT NULL,
    delete_at timestamp without time zone,
    ticket_quota integer DEFAULT 1 NOT NULL,
    ticket_expire_month integer DEFAULT 1 NOT NULL,
    option_type character varying DEFAULT 'primary'::character varying NOT NULL
);


--
-- Name: booking_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_options_id_seq OWNED BY public.booking_options.id;


--
-- Name: booking_page_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_page_options (
    id bigint NOT NULL,
    booking_page_id bigint NOT NULL,
    booking_option_id bigint NOT NULL,
    "position" integer DEFAULT 0,
    online_payment_enabled boolean DEFAULT false
);


--
-- Name: booking_page_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_page_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_page_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_page_options_id_seq OWNED BY public.booking_page_options.id;


--
-- Name: booking_page_special_dates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_page_special_dates (
    id bigint NOT NULL,
    booking_page_id bigint NOT NULL,
    start_at timestamp without time zone NOT NULL,
    end_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: booking_page_special_dates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_page_special_dates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_page_special_dates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_page_special_dates_id_seq OWNED BY public.booking_page_special_dates.id;


--
-- Name: booking_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_pages (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    shop_id bigint NOT NULL,
    name character varying NOT NULL,
    title character varying,
    greeting text,
    note text,
    "interval" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    overbooking_restriction boolean DEFAULT true,
    draft boolean DEFAULT true NOT NULL,
    booking_limit_day integer DEFAULT 1 NOT NULL,
    line_sharing boolean DEFAULT true,
    slug character varying,
    deleted_at timestamp without time zone,
    specific_booking_start_times character varying[],
    online_payment_enabled boolean DEFAULT false,
    event_booking boolean DEFAULT false,
    bookable_restriction_months integer DEFAULT 3,
    default_provider character varying,
    social_account_skippable boolean DEFAULT false NOT NULL,
    rich_menu_only boolean DEFAULT false,
    customer_cancel_request boolean DEFAULT false,
    customer_cancel_request_before_day integer DEFAULT 1 NOT NULL,
    payment_option character varying DEFAULT 'offline'::character varying,
    booking_limit_hours integer DEFAULT 0 NOT NULL,
    cut_off_time timestamp(6) without time zone DEFAULT NULL::timestamp without time zone,
    multiple_selection boolean DEFAULT false,
    settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    use_shop_default_message boolean DEFAULT true NOT NULL
);


--
-- Name: booking_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.booking_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: booking_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.booking_pages_id_seq OWNED BY public.booking_pages.id;


--
-- Name: broadcasts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.broadcasts (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    content text NOT NULL,
    query jsonb,
    schedule_at timestamp without time zone,
    sent_at timestamp without time zone,
    state integer DEFAULT 0,
    recipients_count integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    query_type character varying,
    customers_permission_warning boolean DEFAULT false,
    receiver_ids jsonb DEFAULT '[]'::jsonb,
    builder_type character varying,
    builder_id bigint
);


--
-- Name: broadcasts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.broadcasts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: broadcasts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.broadcasts_id_seq OWNED BY public.broadcasts.id;


--
-- Name: bundled_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bundled_services (
    id bigint NOT NULL,
    bundler_online_service_id integer NOT NULL,
    online_service_id integer NOT NULL,
    end_at timestamp without time zone,
    end_on_days integer,
    end_on_months integer,
    subscription boolean DEFAULT false
);


--
-- Name: bundled_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bundled_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bundled_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bundled_services_id_seq OWNED BY public.bundled_services.id;


--
-- Name: business_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.business_applications (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    state integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: business_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.business_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: business_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.business_applications_id_seq OWNED BY public.business_applications.id;


--
-- Name: business_schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.business_schedules (
    id integer NOT NULL,
    shop_id integer,
    staff_id integer,
    full_time boolean,
    business_state character varying,
    day_of_week integer,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    booking_page_id integer
);


--
-- Name: business_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.business_schedules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: business_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.business_schedules_id_seq OWNED BY public.business_schedules.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id integer NOT NULL,
    user_id integer,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: chapters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chapters (
    id bigint NOT NULL,
    online_service_id bigint,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    "position" integer DEFAULT 0
);


--
-- Name: chapters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chapters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chapters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chapters_id_seq OWNED BY public.chapters.id;


--
-- Name: consultant_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.consultant_accounts (
    id bigint NOT NULL,
    consultant_user_id bigint NOT NULL,
    phone_number character varying NOT NULL,
    token character varying NOT NULL,
    state integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: consultant_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.consultant_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consultant_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.consultant_accounts_id_seq OWNED BY public.consultant_accounts.id;


--
-- Name: contact_group_rankings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contact_group_rankings (
    id integer NOT NULL,
    contact_group_id integer,
    rank_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: contact_group_rankings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contact_group_rankings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contact_group_rankings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contact_group_rankings_id_seq OWNED BY public.contact_group_rankings.id;


--
-- Name: contact_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contact_groups (
    id integer NOT NULL,
    user_id integer NOT NULL,
    google_uid character varying,
    google_group_name character varying,
    google_group_id character varying,
    backup_google_group_id character varying,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    bind_all boolean
);


--
-- Name: contact_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contact_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contact_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contact_groups_id_seq OWNED BY public.contact_groups.id;


--
-- Name: custom_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_messages (
    id bigint NOT NULL,
    scenario character varying NOT NULL,
    service_type character varying,
    service_id bigint,
    content text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    after_days integer,
    receiver_ids character varying[] DEFAULT '{}'::character varying[],
    flex_template character varying,
    content_type character varying DEFAULT 'text'::character varying,
    before_minutes integer,
    nth_time integer DEFAULT 1,
    locale character varying DEFAULT 'ja'::character varying
);


--
-- Name: custom_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_messages_id_seq OWNED BY public.custom_messages.id;


--
-- Name: custom_schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_schedules (
    id integer NOT NULL,
    shop_id integer,
    staff_id integer,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    reason text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    open boolean DEFAULT false NOT NULL,
    user_id integer
);


--
-- Name: custom_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_schedules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_schedules_id_seq OWNED BY public.custom_schedules.id;


--
-- Name: customer_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_payments (
    id bigint NOT NULL,
    customer_id bigint,
    amount_cents numeric,
    amount_currency character varying,
    product_id integer,
    product_type character varying,
    state integer DEFAULT 0 NOT NULL,
    charge_at timestamp without time zone,
    expired_at timestamp without time zone,
    manual boolean DEFAULT false NOT NULL,
    stripe_charge_details jsonb,
    order_id character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    memo character varying,
    provider character varying DEFAULT 'stripe_connect'::character varying
);


--
-- Name: customer_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_payments_id_seq OWNED BY public.customer_payments.id;


--
-- Name: customer_ticket_consumers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_ticket_consumers (
    id bigint NOT NULL,
    customer_ticket_id bigint NOT NULL,
    consumer_type character varying NOT NULL,
    consumer_id bigint NOT NULL,
    ticket_quota_consumed integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: customer_ticket_consumers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_ticket_consumers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_ticket_consumers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_ticket_consumers_id_seq OWNED BY public.customer_ticket_consumers.id;


--
-- Name: customer_tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_tickets (
    id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    total_quota integer NOT NULL,
    consumed_quota integer DEFAULT 0 NOT NULL,
    state character varying NOT NULL,
    code character varying NOT NULL,
    expire_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: customer_tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_tickets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_tickets_id_seq OWNED BY public.customer_tickets.id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customers (
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
    email_types character varying,
    deleted_at timestamp without time zone,
    reminder_permission boolean DEFAULT true,
    phone_numbers_details jsonb,
    emails_details jsonb,
    address_details jsonb,
    stripe_customer_id character varying,
    menu_ids character varying[] DEFAULT '{}'::character varying[],
    online_service_ids character varying[] DEFAULT '{}'::character varying[],
    mixpanel_profile_last_set_at timestamp without time zone,
    square_customer_id character varying,
    tags character varying[] DEFAULT '{}'::character varying[],
    customer_email character varying,
    customer_phone_number character varying
);


--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customers_id_seq OWNED BY public.customers.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
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
    updated_at timestamp without time zone,
    signature character varying
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_jobs_id_seq OWNED BY public.delayed_jobs.id;


--
-- Name: episodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.episodes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    online_service_id bigint NOT NULL,
    name character varying NOT NULL,
    solution_type character varying NOT NULL,
    content_url character varying NOT NULL,
    note text,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tags character varying[] DEFAULT '{}'::character varying[]
);


--
-- Name: episodes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.episodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: episodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.episodes_id_seq OWNED BY public.episodes.id;


--
-- Name: equipments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.equipments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    shop_id bigint NOT NULL,
    deleted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: equipments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.equipments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: equipments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.equipments_id_seq OWNED BY public.equipments.id;


--
-- Name: filtered_outcomes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.filtered_outcomes (
    id integer NOT NULL,
    user_id integer NOT NULL,
    filter_id integer,
    query jsonb,
    file character varying,
    page_size character varying,
    outcome_type character varying,
    aasm_state character varying NOT NULL,
    created_at timestamp without time zone,
    name character varying
);


--
-- Name: filtered_outcomes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.filtered_outcomes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: filtered_outcomes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.filtered_outcomes_id_seq OWNED BY public.filtered_outcomes.id;


--
-- Name: function_accesses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.function_accesses (
    id bigint NOT NULL,
    content character varying NOT NULL,
    source_type character varying,
    source_id character varying,
    action_type character varying,
    access_date date NOT NULL,
    access_count integer DEFAULT 0 NOT NULL,
    conversion_count integer DEFAULT 0 NOT NULL,
    revenue_cents integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    label character varying
);


--
-- Name: function_accesses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.function_accesses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: function_accesses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.function_accesses_id_seq OWNED BY public.function_accesses.id;


--
-- Name: lessons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lessons (
    id bigint NOT NULL,
    chapter_id bigint,
    name character varying,
    solution_type character varying,
    content_url character varying,
    note text,
    start_after_days integer,
    start_at timestamp without time zone,
    "position" integer DEFAULT 0
);


--
-- Name: lessons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lessons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lessons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lessons_id_seq OWNED BY public.lessons.id;


--
-- Name: line_notice_charges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.line_notice_charges (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    reservation_id bigint NOT NULL,
    line_notice_request_id bigint NOT NULL,
    amount numeric NOT NULL,
    amount_currency character varying DEFAULT 'JPY'::character varying NOT NULL,
    state integer DEFAULT 0 NOT NULL,
    charge_date date NOT NULL,
    is_free_trial boolean DEFAULT false NOT NULL,
    stripe_charge_details jsonb,
    details jsonb,
    order_id character varying,
    payment_intent_id character varying,
    error_message text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: line_notice_charges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.line_notice_charges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: line_notice_charges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.line_notice_charges_id_seq OWNED BY public.line_notice_charges.id;


--
-- Name: line_notice_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.line_notice_requests (
    id bigint NOT NULL,
    reservation_id bigint NOT NULL,
    user_id bigint NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    approved_at timestamp(6) without time zone,
    rejected_at timestamp(6) without time zone,
    expired_at timestamp(6) without time zone,
    rejection_reason text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: line_notice_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.line_notice_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: line_notice_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.line_notice_requests_id_seq OWNED BY public.line_notice_requests.id;


--
-- Name: menu_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_categories (
    id integer NOT NULL,
    menu_id integer,
    category_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: menu_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menu_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menu_categories_id_seq OWNED BY public.menu_categories.id;


--
-- Name: menu_equipments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_equipments (
    id bigint NOT NULL,
    menu_id bigint NOT NULL,
    equipment_id bigint NOT NULL,
    required_quantity integer DEFAULT 1 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: menu_equipments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menu_equipments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_equipments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menu_equipments_id_seq OWNED BY public.menu_equipments.id;


--
-- Name: menu_reservation_setting_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_reservation_setting_rules (
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

CREATE SEQUENCE public.menu_reservation_setting_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_reservation_setting_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menu_reservation_setting_rules_id_seq OWNED BY public.menu_reservation_setting_rules.id;


--
-- Name: menus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menus (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying NOT NULL,
    short_name character varying,
    minutes integer,
    "interval" integer,
    min_staffs_number integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    online boolean DEFAULT false
);


--
-- Name: menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menus_id_seq OWNED BY public.menus.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    user_id integer,
    phone_number character varying,
    content text,
    customer_id integer,
    reservation_id integer,
    charged boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: online_service_customer_relations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.online_service_customer_relations (
    id bigint NOT NULL,
    online_service_id integer NOT NULL,
    sale_page_id integer,
    customer_id integer NOT NULL,
    payment_state integer DEFAULT 0 NOT NULL,
    permission_state integer DEFAULT 0 NOT NULL,
    paid_at timestamp without time zone,
    expire_at timestamp without time zone,
    product_details json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    current boolean DEFAULT true,
    watched_lesson_ids character varying[] DEFAULT '{}'::character varying[],
    stripe_subscription_id character varying,
    bundled_service_id integer,
    function_access_id bigint
);


--
-- Name: online_service_customer_relations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.online_service_customer_relations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: online_service_customer_relations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.online_service_customer_relations_id_seq OWNED BY public.online_service_customer_relations.id;


--
-- Name: online_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.online_services (
    id bigint NOT NULL,
    user_id bigint,
    name character varying NOT NULL,
    goal_type character varying NOT NULL,
    solution_type character varying NOT NULL,
    end_at timestamp without time zone,
    end_on_days integer,
    upsell_sale_page_id integer,
    content json,
    company_type character varying NOT NULL,
    company_id bigint NOT NULL,
    slug character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    start_at timestamp without time zone,
    content_url character varying,
    tags character varying[] DEFAULT '{}'::character varying[],
    stripe_product_id character varying,
    note text,
    external_purchase_url character varying,
    internal_name character varying,
    deleted_at timestamp(6) without time zone,
    settings jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: online_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.online_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: online_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.online_services_id_seq OWNED BY public.online_services.id;


--
-- Name: payment_withdrawals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_withdrawals (
    id bigint NOT NULL,
    receiver_id integer NOT NULL,
    state integer DEFAULT 0 NOT NULL,
    amount_cents numeric NOT NULL,
    amount_currency character varying NOT NULL,
    order_id character varying,
    details jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: payment_withdrawals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_withdrawals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_withdrawals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_withdrawals_id_seq OWNED BY public.payment_withdrawals.id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id bigint NOT NULL,
    receiver_id integer NOT NULL,
    referrer_id integer,
    payment_withdrawal_id integer,
    charge_id integer,
    amount_cents numeric NOT NULL,
    amount_currency character varying NOT NULL,
    details jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payments_id_seq OWNED BY public.payments.id;


--
-- Name: pghero_query_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pghero_query_stats (
    id bigint NOT NULL,
    database text,
    "user" text,
    query text,
    query_hash bigint,
    total_time double precision,
    calls bigint,
    captured_at timestamp without time zone
);


--
-- Name: pghero_query_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pghero_query_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pghero_query_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pghero_query_stats_id_seq OWNED BY public.pghero_query_stats.id;


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plans (
    id bigint NOT NULL,
    "position" integer,
    level integer
);


--
-- Name: plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plans_id_seq OWNED BY public.plans.id;


--
-- Name: product_requirements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_requirements (
    id bigint NOT NULL,
    requirer_type character varying NOT NULL,
    requirer_id bigint NOT NULL,
    requirement_type character varying NOT NULL,
    requirement_id bigint NOT NULL,
    sale_page_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: product_requirements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_requirements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_requirements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_requirements_id_seq OWNED BY public.product_requirements.id;


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
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
    updated_at timestamp without time zone NOT NULL,
    company_zip_code character varying,
    company_address character varying,
    company_phone_number character varying,
    email character varying,
    region character varying,
    city character varying,
    street1 character varying,
    street2 character varying,
    template_variables json,
    personal_address_details jsonb,
    company_address_details jsonb,
    context jsonb,
    company_email character varying
);


--
-- Name: profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.profiles_id_seq OWNED BY public.profiles.id;


--
-- Name: query_filters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.query_filters (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying NOT NULL,
    type character varying NOT NULL,
    query jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: query_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.query_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: query_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.query_filters_id_seq OWNED BY public.query_filters.id;


--
-- Name: question_answers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_answers (
    id bigint NOT NULL,
    survey_response_id bigint NOT NULL,
    survey_question_id bigint NOT NULL,
    survey_option_id bigint,
    survey_question_snapshot text NOT NULL,
    survey_option_snapshot text,
    text_answer text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    survey_activity_id bigint
);


--
-- Name: question_answers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.question_answers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_answers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.question_answers_id_seq OWNED BY public.question_answers.id;


--
-- Name: ranks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ranks (
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

CREATE SEQUENCE public.ranks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ranks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ranks_id_seq OWNED BY public.ranks.id;


--
-- Name: referral_credits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.referral_credits (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    referral_id bigint,
    subscription_charge_id bigint,
    amount numeric NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: referral_credits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.referral_credits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: referral_credits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.referral_credits_id_seq OWNED BY public.referral_credits.id;


--
-- Name: referrals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.referrals (
    id bigint NOT NULL,
    referrer_id integer NOT NULL,
    referee_id integer NOT NULL,
    state integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: referrals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.referrals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: referrals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.referrals_id_seq OWNED BY public.referrals.id;


--
-- Name: reservation_booking_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservation_booking_options (
    id bigint NOT NULL,
    reservation_id bigint,
    booking_option_id bigint
);


--
-- Name: reservation_booking_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reservation_booking_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservation_booking_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reservation_booking_options_id_seq OWNED BY public.reservation_booking_options.id;


--
-- Name: reservation_customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservation_customers (
    id integer NOT NULL,
    reservation_id integer NOT NULL,
    customer_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    booking_page_id integer,
    booking_option_id integer,
    state integer DEFAULT 0,
    booking_amount_currency character varying,
    booking_amount_cents numeric,
    tax_include boolean,
    booking_at timestamp without time zone,
    details jsonb,
    payment_state integer DEFAULT 0,
    sale_page_id integer,
    nth_quota integer,
    customer_ticket_id integer,
    slug character varying,
    cancel_reason character varying,
    function_access_id bigint,
    booking_option_ids jsonb DEFAULT '[]'::jsonb,
    customer_tickets_quota jsonb DEFAULT '{}'::jsonb,
    survey_activity_id integer
);


--
-- Name: reservation_customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reservation_customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservation_customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reservation_customers_id_seq OWNED BY public.reservation_customers.id;


--
-- Name: reservation_menus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservation_menus (
    id bigint NOT NULL,
    reservation_id bigint,
    menu_id bigint,
    "position" integer,
    required_time integer
);


--
-- Name: reservation_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reservation_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservation_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reservation_menus_id_seq OWNED BY public.reservation_menus.id;


--
-- Name: reservation_setting_menus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservation_setting_menus (
    id integer NOT NULL,
    reservation_setting_id integer,
    menu_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: reservation_setting_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reservation_setting_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservation_setting_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reservation_setting_menus_id_seq OWNED BY public.reservation_setting_menus.id;


--
-- Name: reservation_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservation_settings (
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

CREATE SEQUENCE public.reservation_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservation_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reservation_settings_id_seq OWNED BY public.reservation_settings.id;


--
-- Name: reservation_staffs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservation_staffs (
    id integer NOT NULL,
    reservation_id integer NOT NULL,
    staff_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    state integer DEFAULT 0,
    menu_id integer,
    prepare_time timestamp without time zone,
    work_start_at timestamp without time zone,
    work_end_at timestamp without time zone,
    ready_time timestamp without time zone
);


--
-- Name: reservation_staffs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reservation_staffs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservation_staffs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reservation_staffs_id_seq OWNED BY public.reservation_staffs.id;


--
-- Name: reservations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservations (
    id integer NOT NULL,
    shop_id integer NOT NULL,
    menu_id integer,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    ready_time timestamp without time zone NOT NULL,
    aasm_state character varying NOT NULL,
    memo text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    count_of_customers integer DEFAULT 0,
    with_warnings boolean DEFAULT false NOT NULL,
    by_staff_id integer,
    deleted_at timestamp without time zone,
    prepare_time timestamp without time zone,
    user_id integer,
    online boolean DEFAULT false,
    meeting_url character varying,
    survey_activity_id integer,
    survey_activity_slot_id integer
);


--
-- Name: reservations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reservations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reservations_id_seq OWNED BY public.reservations.id;


--
-- Name: sale_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_pages (
    id bigint NOT NULL,
    user_id bigint,
    staff_id bigint,
    product_type character varying NOT NULL,
    product_id bigint NOT NULL,
    sale_template_id bigint,
    sale_template_variables json,
    content json,
    flow json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    slug character varying,
    introduction_video_url character varying,
    quantity integer,
    selling_end_at timestamp without time zone,
    selling_start_at timestamp without time zone,
    normal_price_amount_cents numeric,
    selling_price_amount_cents numeric,
    sections_context jsonb,
    deleted_at timestamp without time zone,
    selling_multiple_times_price character varying[] DEFAULT '{}'::character varying[],
    internal_name character varying,
    recurring_prices jsonb DEFAULT '{"default": {}}'::jsonb,
    published boolean DEFAULT true,
    draft boolean DEFAULT false,
    map_public boolean DEFAULT false
);


--
-- Name: sale_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sale_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sale_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sale_pages_id_seq OWNED BY public.sale_pages.id;


--
-- Name: sale_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_templates (
    id bigint NOT NULL,
    edit_body json,
    view_body json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    locale character varying DEFAULT 'ja'::character varying NOT NULL
);


--
-- Name: sale_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sale_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sale_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sale_templates_id_seq OWNED BY public.sale_templates.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: shop_menu_repeating_dates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shop_menu_repeating_dates (
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

CREATE SEQUENCE public.shop_menu_repeating_dates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shop_menu_repeating_dates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shop_menu_repeating_dates_id_seq OWNED BY public.shop_menu_repeating_dates.id;


--
-- Name: shop_menus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shop_menus (
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

CREATE SEQUENCE public.shop_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shop_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shop_menus_id_seq OWNED BY public.shop_menus.id;


--
-- Name: shop_staffs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shop_staffs (
    id integer NOT NULL,
    shop_id integer,
    staff_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    staff_regular_working_day_permission boolean DEFAULT false NOT NULL,
    staff_temporary_working_day_permission boolean DEFAULT false NOT NULL,
    staff_full_time_permission boolean DEFAULT false NOT NULL,
    level integer DEFAULT 0 NOT NULL
);


--
-- Name: shop_staffs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shop_staffs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shop_staffs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shop_staffs_id_seq OWNED BY public.shop_staffs.id;


--
-- Name: shops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shops (
    id integer NOT NULL,
    user_id integer,
    name character varying NOT NULL,
    short_name character varying NOT NULL,
    zip_code character varying NOT NULL,
    phone_number character varying,
    email character varying,
    address character varying NOT NULL,
    website character varying,
    holiday_working boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    template_variables json,
    address_details jsonb,
    holiday_working_option character varying DEFAULT 'holiday_schedule_without_business_schedule'::character varying
);


--
-- Name: shops_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shops_id_seq OWNED BY public.shops.id;


--
-- Name: social_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_accounts (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    channel_id character varying,
    channel_token character varying,
    channel_secret character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    label character varying,
    basic_id character varying,
    login_channel_id character varying,
    login_channel_secret character varying
);


--
-- Name: social_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.social_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.social_accounts_id_seq OWNED BY public.social_accounts.id;


--
-- Name: social_customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_customers (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    customer_id bigint,
    social_account_id integer,
    social_user_id character varying NOT NULL,
    social_user_name character varying,
    social_user_picture_url character varying,
    conversation_state integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    social_rich_menu_key character varying,
    is_owner boolean DEFAULT false,
    locale character varying DEFAULT 'ja'::character varying
);


--
-- Name: social_customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.social_customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social_customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.social_customers_id_seq OWNED BY public.social_customers.id;


--
-- Name: social_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_messages (
    id bigint NOT NULL,
    social_account_id integer,
    social_customer_id integer,
    staff_id integer,
    raw_content text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    readed_at timestamp without time zone,
    message_type integer DEFAULT 0,
    schedule_at timestamp without time zone,
    sent_at timestamp without time zone,
    broadcast_id integer,
    content_type character varying,
    channel character varying,
    customer_id integer,
    user_id integer
);


--
-- Name: social_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.social_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.social_messages_id_seq OWNED BY public.social_messages.id;


--
-- Name: social_rich_menus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_rich_menus (
    id bigint NOT NULL,
    social_account_id integer,
    social_rich_menu_id character varying,
    social_name character varying,
    body jsonb,
    current boolean,
    "default" boolean,
    start_at timestamp(6) without time zone,
    end_at timestamp(6) without time zone,
    internal_name character varying,
    bar_label character varying,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    locale character varying DEFAULT 'ja'::character varying NOT NULL
);


--
-- Name: social_rich_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.social_rich_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social_rich_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.social_rich_menus_id_seq OWNED BY public.social_rich_menus.id;


--
-- Name: social_user_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_user_messages (
    id bigint NOT NULL,
    social_user_id integer NOT NULL,
    admin_user_id integer,
    message_type integer,
    readed_at timestamp without time zone,
    raw_content text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    schedule_at timestamp without time zone,
    sent_at timestamp without time zone,
    content_type character varying,
    slack_message_id character varying,
    scenario character varying,
    nth_time integer,
    ai_uid character varying,
    custom_message_id integer
);


--
-- Name: social_user_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.social_user_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social_user_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.social_user_messages_id_seq OWNED BY public.social_user_messages.id;


--
-- Name: social_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_users (
    id bigint NOT NULL,
    user_id bigint,
    social_service_user_id character varying NOT NULL,
    social_user_name character varying,
    social_user_picture_url character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    social_rich_menu_key character varying,
    pinned boolean DEFAULT false NOT NULL,
    release_version character varying,
    consultant_at timestamp(6) without time zone,
    locale character varying DEFAULT 'ja'::character varying,
    email character varying
);


--
-- Name: social_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.social_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.social_users_id_seq OWNED BY public.social_users.id;


--
-- Name: staff_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_accounts (
    id integer NOT NULL,
    email character varying,
    user_id integer,
    owner_id integer NOT NULL,
    staff_id integer NOT NULL,
    token character varying,
    state integer DEFAULT 0 NOT NULL,
    level integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    active_uniqueness boolean,
    phone_number character varying
);


--
-- Name: staff_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.staff_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.staff_accounts_id_seq OWNED BY public.staff_accounts.id;


--
-- Name: staff_contact_group_relations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_contact_group_relations (
    id bigint NOT NULL,
    staff_id bigint NOT NULL,
    contact_group_id bigint NOT NULL,
    contact_group_read_permission integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: staff_contact_group_relations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.staff_contact_group_relations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff_contact_group_relations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.staff_contact_group_relations_id_seq OWNED BY public.staff_contact_group_relations.id;


--
-- Name: staff_menus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_menus (
    id integer NOT NULL,
    staff_id integer NOT NULL,
    menu_id integer NOT NULL,
    max_customers integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    priority integer
);


--
-- Name: staff_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.staff_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.staff_menus_id_seq OWNED BY public.staff_menus.id;


--
-- Name: staffs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staffs (
    id integer NOT NULL,
    user_id integer NOT NULL,
    last_name character varying,
    first_name character varying,
    phonetic_last_name character varying,
    phonetic_first_name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    staff_holiday_permission boolean DEFAULT false NOT NULL,
    introduction text
);


--
-- Name: staffs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.staffs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staffs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.staffs_id_seq OWNED BY public.staffs.id;


--
-- Name: subscription_charges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscription_charges (
    id bigint NOT NULL,
    user_id bigint,
    plan_id bigint,
    amount_cents numeric,
    amount_currency character varying,
    state integer DEFAULT 0 NOT NULL,
    charge_date date,
    expired_date date,
    manual boolean DEFAULT false NOT NULL,
    stripe_charge_details jsonb,
    order_id character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    details jsonb,
    rank integer DEFAULT 0,
    error_message text
);


--
-- Name: subscription_charges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subscription_charges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscription_charges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subscription_charges_id_seq OWNED BY public.subscription_charges.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id bigint NOT NULL,
    plan_id bigint,
    next_plan_id integer,
    user_id bigint,
    stripe_customer_id character varying,
    recurring_day integer,
    expired_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    rank integer DEFAULT 0,
    trial_days integer,
    trial_expired_date date,
    earned_credits numeric DEFAULT 0.0 NOT NULL,
    remaining_credits numeric DEFAULT 0.0 NOT NULL
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subscriptions_id_seq OWNED BY public.subscriptions.id;


--
-- Name: survey_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.survey_activities (
    id bigint NOT NULL,
    survey_question_id bigint NOT NULL,
    survey_id bigint NOT NULL,
    name character varying NOT NULL,
    "position" integer,
    max_participants integer,
    price_cents integer,
    currency character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: survey_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.survey_activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: survey_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.survey_activities_id_seq OWNED BY public.survey_activities.id;


--
-- Name: survey_activity_slots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.survey_activity_slots (
    id bigint NOT NULL,
    survey_activity_id bigint NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: survey_activity_slots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.survey_activity_slots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: survey_activity_slots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.survey_activity_slots_id_seq OWNED BY public.survey_activity_slots.id;


--
-- Name: survey_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.survey_options (
    id bigint NOT NULL,
    survey_question_id bigint NOT NULL,
    content character varying NOT NULL,
    "position" integer,
    deleted_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: survey_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.survey_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: survey_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.survey_options_id_seq OWNED BY public.survey_options.id;


--
-- Name: survey_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.survey_questions (
    id bigint NOT NULL,
    survey_id bigint NOT NULL,
    description text NOT NULL,
    question_type character varying NOT NULL,
    required boolean DEFAULT false,
    "position" integer,
    deleted_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: survey_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.survey_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: survey_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.survey_questions_id_seq OWNED BY public.survey_questions.id;


--
-- Name: survey_responses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.survey_responses (
    id bigint NOT NULL,
    survey_id bigint NOT NULL,
    owner_type character varying,
    owner_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    survey_activity_id integer,
    uuid character varying,
    state integer DEFAULT 0
);


--
-- Name: survey_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.survey_responses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: survey_responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.survey_responses_id_seq OWNED BY public.survey_responses.id;


--
-- Name: surveys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.surveys (
    id bigint NOT NULL,
    title character varying,
    description text,
    active boolean DEFAULT true,
    user_id bigint NOT NULL,
    owner_type character varying,
    owner_id bigint,
    scenario character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    slug character varying,
    deleted_at timestamp without time zone
);


--
-- Name: surveys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.surveys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: surveys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.surveys_id_seq OWNED BY public.surveys.id;


--
-- Name: taggings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.taggings (
    id integer NOT NULL,
    tag_id integer,
    taggable_type character varying,
    taggable_id integer,
    tagger_type character varying,
    tagger_id integer,
    context character varying(128),
    created_at timestamp without time zone
);


--
-- Name: taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.taggings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.taggings_id_seq OWNED BY public.taggings.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    taggings_count integer DEFAULT 0
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: ticket_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ticket_products (
    id bigint NOT NULL,
    ticket_id bigint NOT NULL,
    product_type character varying NOT NULL,
    product_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ticket_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ticket_products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ticket_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ticket_products_id_seq OWNED BY public.ticket_products.id;


--
-- Name: tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tickets (
    id bigint NOT NULL,
    user_id bigint,
    ticket_type character varying DEFAULT 'single'::character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tickets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tickets_id_seq OWNED BY public.tickets.id;


--
-- Name: user_metrics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_metrics (
    id bigint NOT NULL,
    user_id bigint,
    content json DEFAULT '{}'::json
);


--
-- Name: user_metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_metrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_metrics_id_seq OWNED BY public.user_metrics.id;


--
-- Name: user_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_settings (
    id bigint NOT NULL,
    user_id bigint,
    content json DEFAULT '{}'::json
);


--
-- Name: user_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_settings_id_seq OWNED BY public.user_settings.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying,
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
    contacts_sync_at timestamp without time zone,
    referral_token character varying,
    phone_number character varying,
    customers_count integer DEFAULT 0,
    customer_latest_activity_at timestamp without time zone,
    public_id uuid NOT NULL,
    mixpanel_profile_last_set_at timestamp without time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id bigint NOT NULL,
    item_type character varying NOT NULL,
    item_id integer NOT NULL,
    event character varying NOT NULL,
    whodunnit character varying,
    object text,
    created_at timestamp without time zone
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: web_push_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.web_push_subscriptions (
    id bigint NOT NULL,
    user_id bigint,
    endpoint character varying,
    p256dh_key character varying,
    auth_key character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: web_push_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.web_push_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: web_push_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.web_push_subscriptions_id_seq OWNED BY public.web_push_subscriptions.id;


--
-- Name: access_providers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_providers ALTER COLUMN id SET DEFAULT nextval('public.access_providers_id_seq'::regclass);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: ahoy_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_events ALTER COLUMN id SET DEFAULT nextval('public.ahoy_events_id_seq'::regclass);


--
-- Name: ahoy_visits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_visits ALTER COLUMN id SET DEFAULT nextval('public.ahoy_visits_id_seq'::regclass);


--
-- Name: ai_faqs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_faqs ALTER COLUMN id SET DEFAULT nextval('public.ai_faqs_id_seq'::regclass);


--
-- Name: blazer_audits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_audits ALTER COLUMN id SET DEFAULT nextval('public.blazer_audits_id_seq'::regclass);


--
-- Name: blazer_checks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_checks ALTER COLUMN id SET DEFAULT nextval('public.blazer_checks_id_seq'::regclass);


--
-- Name: blazer_dashboard_queries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_dashboard_queries ALTER COLUMN id SET DEFAULT nextval('public.blazer_dashboard_queries_id_seq'::regclass);


--
-- Name: blazer_dashboards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_dashboards ALTER COLUMN id SET DEFAULT nextval('public.blazer_dashboards_id_seq'::regclass);


--
-- Name: blazer_queries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_queries ALTER COLUMN id SET DEFAULT nextval('public.blazer_queries_id_seq'::regclass);


--
-- Name: booking_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_codes ALTER COLUMN id SET DEFAULT nextval('public.booking_codes_id_seq'::regclass);


--
-- Name: booking_option_menus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_option_menus ALTER COLUMN id SET DEFAULT nextval('public.booking_option_menus_id_seq'::regclass);


--
-- Name: booking_options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_options ALTER COLUMN id SET DEFAULT nextval('public.booking_options_id_seq'::regclass);


--
-- Name: booking_page_options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_page_options ALTER COLUMN id SET DEFAULT nextval('public.booking_page_options_id_seq'::regclass);


--
-- Name: booking_page_special_dates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_page_special_dates ALTER COLUMN id SET DEFAULT nextval('public.booking_page_special_dates_id_seq'::regclass);


--
-- Name: booking_pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_pages ALTER COLUMN id SET DEFAULT nextval('public.booking_pages_id_seq'::regclass);


--
-- Name: broadcasts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.broadcasts ALTER COLUMN id SET DEFAULT nextval('public.broadcasts_id_seq'::regclass);


--
-- Name: bundled_services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bundled_services ALTER COLUMN id SET DEFAULT nextval('public.bundled_services_id_seq'::regclass);


--
-- Name: business_applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_applications ALTER COLUMN id SET DEFAULT nextval('public.business_applications_id_seq'::regclass);


--
-- Name: business_schedules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_schedules ALTER COLUMN id SET DEFAULT nextval('public.business_schedules_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: chapters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapters ALTER COLUMN id SET DEFAULT nextval('public.chapters_id_seq'::regclass);


--
-- Name: consultant_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consultant_accounts ALTER COLUMN id SET DEFAULT nextval('public.consultant_accounts_id_seq'::regclass);


--
-- Name: contact_group_rankings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_group_rankings ALTER COLUMN id SET DEFAULT nextval('public.contact_group_rankings_id_seq'::regclass);


--
-- Name: contact_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_groups ALTER COLUMN id SET DEFAULT nextval('public.contact_groups_id_seq'::regclass);


--
-- Name: custom_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_messages ALTER COLUMN id SET DEFAULT nextval('public.custom_messages_id_seq'::regclass);


--
-- Name: custom_schedules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_schedules ALTER COLUMN id SET DEFAULT nextval('public.custom_schedules_id_seq'::regclass);


--
-- Name: customer_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_payments ALTER COLUMN id SET DEFAULT nextval('public.customer_payments_id_seq'::regclass);


--
-- Name: customer_ticket_consumers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_ticket_consumers ALTER COLUMN id SET DEFAULT nextval('public.customer_ticket_consumers_id_seq'::regclass);


--
-- Name: customer_tickets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_tickets ALTER COLUMN id SET DEFAULT nextval('public.customer_tickets_id_seq'::regclass);


--
-- Name: customers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers ALTER COLUMN id SET DEFAULT nextval('public.customers_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: episodes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.episodes ALTER COLUMN id SET DEFAULT nextval('public.episodes_id_seq'::regclass);


--
-- Name: equipments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipments ALTER COLUMN id SET DEFAULT nextval('public.equipments_id_seq'::regclass);


--
-- Name: filtered_outcomes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filtered_outcomes ALTER COLUMN id SET DEFAULT nextval('public.filtered_outcomes_id_seq'::regclass);


--
-- Name: function_accesses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.function_accesses ALTER COLUMN id SET DEFAULT nextval('public.function_accesses_id_seq'::regclass);


--
-- Name: lessons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lessons ALTER COLUMN id SET DEFAULT nextval('public.lessons_id_seq'::regclass);


--
-- Name: line_notice_charges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.line_notice_charges ALTER COLUMN id SET DEFAULT nextval('public.line_notice_charges_id_seq'::regclass);


--
-- Name: line_notice_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.line_notice_requests ALTER COLUMN id SET DEFAULT nextval('public.line_notice_requests_id_seq'::regclass);


--
-- Name: menu_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_categories ALTER COLUMN id SET DEFAULT nextval('public.menu_categories_id_seq'::regclass);


--
-- Name: menu_equipments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_equipments ALTER COLUMN id SET DEFAULT nextval('public.menu_equipments_id_seq'::regclass);


--
-- Name: menu_reservation_setting_rules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_reservation_setting_rules ALTER COLUMN id SET DEFAULT nextval('public.menu_reservation_setting_rules_id_seq'::regclass);


--
-- Name: menus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus ALTER COLUMN id SET DEFAULT nextval('public.menus_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: online_service_customer_relations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_service_customer_relations ALTER COLUMN id SET DEFAULT nextval('public.online_service_customer_relations_id_seq'::regclass);


--
-- Name: online_services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_services ALTER COLUMN id SET DEFAULT nextval('public.online_services_id_seq'::regclass);


--
-- Name: payment_withdrawals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_withdrawals ALTER COLUMN id SET DEFAULT nextval('public.payment_withdrawals_id_seq'::regclass);


--
-- Name: payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments ALTER COLUMN id SET DEFAULT nextval('public.payments_id_seq'::regclass);


--
-- Name: pghero_query_stats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pghero_query_stats ALTER COLUMN id SET DEFAULT nextval('public.pghero_query_stats_id_seq'::regclass);


--
-- Name: plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans ALTER COLUMN id SET DEFAULT nextval('public.plans_id_seq'::regclass);


--
-- Name: product_requirements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_requirements ALTER COLUMN id SET DEFAULT nextval('public.product_requirements_id_seq'::regclass);


--
-- Name: profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles ALTER COLUMN id SET DEFAULT nextval('public.profiles_id_seq'::regclass);


--
-- Name: query_filters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query_filters ALTER COLUMN id SET DEFAULT nextval('public.query_filters_id_seq'::regclass);


--
-- Name: question_answers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_answers ALTER COLUMN id SET DEFAULT nextval('public.question_answers_id_seq'::regclass);


--
-- Name: ranks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ranks ALTER COLUMN id SET DEFAULT nextval('public.ranks_id_seq'::regclass);


--
-- Name: referral_credits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_credits ALTER COLUMN id SET DEFAULT nextval('public.referral_credits_id_seq'::regclass);


--
-- Name: referrals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals ALTER COLUMN id SET DEFAULT nextval('public.referrals_id_seq'::regclass);


--
-- Name: reservation_booking_options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_booking_options ALTER COLUMN id SET DEFAULT nextval('public.reservation_booking_options_id_seq'::regclass);


--
-- Name: reservation_customers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_customers ALTER COLUMN id SET DEFAULT nextval('public.reservation_customers_id_seq'::regclass);


--
-- Name: reservation_menus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_menus ALTER COLUMN id SET DEFAULT nextval('public.reservation_menus_id_seq'::regclass);


--
-- Name: reservation_setting_menus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_setting_menus ALTER COLUMN id SET DEFAULT nextval('public.reservation_setting_menus_id_seq'::regclass);


--
-- Name: reservation_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_settings ALTER COLUMN id SET DEFAULT nextval('public.reservation_settings_id_seq'::regclass);


--
-- Name: reservation_staffs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_staffs ALTER COLUMN id SET DEFAULT nextval('public.reservation_staffs_id_seq'::regclass);


--
-- Name: reservations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations ALTER COLUMN id SET DEFAULT nextval('public.reservations_id_seq'::regclass);


--
-- Name: sale_pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_pages ALTER COLUMN id SET DEFAULT nextval('public.sale_pages_id_seq'::regclass);


--
-- Name: sale_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_templates ALTER COLUMN id SET DEFAULT nextval('public.sale_templates_id_seq'::regclass);


--
-- Name: shop_menu_repeating_dates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_menu_repeating_dates ALTER COLUMN id SET DEFAULT nextval('public.shop_menu_repeating_dates_id_seq'::regclass);


--
-- Name: shop_menus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_menus ALTER COLUMN id SET DEFAULT nextval('public.shop_menus_id_seq'::regclass);


--
-- Name: shop_staffs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_staffs ALTER COLUMN id SET DEFAULT nextval('public.shop_staffs_id_seq'::regclass);


--
-- Name: shops id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shops ALTER COLUMN id SET DEFAULT nextval('public.shops_id_seq'::regclass);


--
-- Name: social_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_accounts ALTER COLUMN id SET DEFAULT nextval('public.social_accounts_id_seq'::regclass);


--
-- Name: social_customers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_customers ALTER COLUMN id SET DEFAULT nextval('public.social_customers_id_seq'::regclass);


--
-- Name: social_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_messages ALTER COLUMN id SET DEFAULT nextval('public.social_messages_id_seq'::regclass);


--
-- Name: social_rich_menus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_rich_menus ALTER COLUMN id SET DEFAULT nextval('public.social_rich_menus_id_seq'::regclass);


--
-- Name: social_user_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_user_messages ALTER COLUMN id SET DEFAULT nextval('public.social_user_messages_id_seq'::regclass);


--
-- Name: social_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_users ALTER COLUMN id SET DEFAULT nextval('public.social_users_id_seq'::regclass);


--
-- Name: staff_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_accounts ALTER COLUMN id SET DEFAULT nextval('public.staff_accounts_id_seq'::regclass);


--
-- Name: staff_contact_group_relations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_contact_group_relations ALTER COLUMN id SET DEFAULT nextval('public.staff_contact_group_relations_id_seq'::regclass);


--
-- Name: staff_menus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_menus ALTER COLUMN id SET DEFAULT nextval('public.staff_menus_id_seq'::regclass);


--
-- Name: staffs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staffs ALTER COLUMN id SET DEFAULT nextval('public.staffs_id_seq'::regclass);


--
-- Name: subscription_charges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_charges ALTER COLUMN id SET DEFAULT nextval('public.subscription_charges_id_seq'::regclass);


--
-- Name: subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN id SET DEFAULT nextval('public.subscriptions_id_seq'::regclass);


--
-- Name: survey_activities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_activities ALTER COLUMN id SET DEFAULT nextval('public.survey_activities_id_seq'::regclass);


--
-- Name: survey_activity_slots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_activity_slots ALTER COLUMN id SET DEFAULT nextval('public.survey_activity_slots_id_seq'::regclass);


--
-- Name: survey_options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_options ALTER COLUMN id SET DEFAULT nextval('public.survey_options_id_seq'::regclass);


--
-- Name: survey_questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_questions ALTER COLUMN id SET DEFAULT nextval('public.survey_questions_id_seq'::regclass);


--
-- Name: survey_responses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_responses ALTER COLUMN id SET DEFAULT nextval('public.survey_responses_id_seq'::regclass);


--
-- Name: surveys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.surveys ALTER COLUMN id SET DEFAULT nextval('public.surveys_id_seq'::regclass);


--
-- Name: taggings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings ALTER COLUMN id SET DEFAULT nextval('public.taggings_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: ticket_products id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_products ALTER COLUMN id SET DEFAULT nextval('public.ticket_products_id_seq'::regclass);


--
-- Name: tickets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets ALTER COLUMN id SET DEFAULT nextval('public.tickets_id_seq'::regclass);


--
-- Name: user_metrics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_metrics ALTER COLUMN id SET DEFAULT nextval('public.user_metrics_id_seq'::regclass);


--
-- Name: user_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_settings ALTER COLUMN id SET DEFAULT nextval('public.user_settings_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: web_push_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_push_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.web_push_subscriptions_id_seq'::regclass);


--
-- Name: access_providers access_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_providers
    ADD CONSTRAINT access_providers_pkey PRIMARY KEY (id);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ahoy_events ahoy_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_events
    ADD CONSTRAINT ahoy_events_pkey PRIMARY KEY (id);


--
-- Name: ahoy_visits ahoy_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ahoy_visits
    ADD CONSTRAINT ahoy_visits_pkey PRIMARY KEY (id);


--
-- Name: ai_faqs ai_faqs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_faqs
    ADD CONSTRAINT ai_faqs_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: blazer_audits blazer_audits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_audits
    ADD CONSTRAINT blazer_audits_pkey PRIMARY KEY (id);


--
-- Name: blazer_checks blazer_checks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_checks
    ADD CONSTRAINT blazer_checks_pkey PRIMARY KEY (id);


--
-- Name: blazer_dashboard_queries blazer_dashboard_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_dashboard_queries
    ADD CONSTRAINT blazer_dashboard_queries_pkey PRIMARY KEY (id);


--
-- Name: blazer_dashboards blazer_dashboards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_dashboards
    ADD CONSTRAINT blazer_dashboards_pkey PRIMARY KEY (id);


--
-- Name: blazer_queries blazer_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blazer_queries
    ADD CONSTRAINT blazer_queries_pkey PRIMARY KEY (id);


--
-- Name: booking_codes booking_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_codes
    ADD CONSTRAINT booking_codes_pkey PRIMARY KEY (id);


--
-- Name: booking_option_menus booking_option_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_option_menus
    ADD CONSTRAINT booking_option_menus_pkey PRIMARY KEY (id);


--
-- Name: booking_options booking_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_options
    ADD CONSTRAINT booking_options_pkey PRIMARY KEY (id);


--
-- Name: booking_page_options booking_page_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_page_options
    ADD CONSTRAINT booking_page_options_pkey PRIMARY KEY (id);


--
-- Name: booking_page_special_dates booking_page_special_dates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_page_special_dates
    ADD CONSTRAINT booking_page_special_dates_pkey PRIMARY KEY (id);


--
-- Name: booking_pages booking_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_pages
    ADD CONSTRAINT booking_pages_pkey PRIMARY KEY (id);


--
-- Name: broadcasts broadcasts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.broadcasts
    ADD CONSTRAINT broadcasts_pkey PRIMARY KEY (id);


--
-- Name: bundled_services bundled_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bundled_services
    ADD CONSTRAINT bundled_services_pkey PRIMARY KEY (id);


--
-- Name: business_applications business_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_applications
    ADD CONSTRAINT business_applications_pkey PRIMARY KEY (id);


--
-- Name: business_schedules business_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_schedules
    ADD CONSTRAINT business_schedules_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: chapters chapters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chapters
    ADD CONSTRAINT chapters_pkey PRIMARY KEY (id);


--
-- Name: consultant_accounts consultant_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consultant_accounts
    ADD CONSTRAINT consultant_accounts_pkey PRIMARY KEY (id);


--
-- Name: contact_group_rankings contact_group_rankings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_group_rankings
    ADD CONSTRAINT contact_group_rankings_pkey PRIMARY KEY (id);


--
-- Name: contact_groups contact_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_groups
    ADD CONSTRAINT contact_groups_pkey PRIMARY KEY (id);


--
-- Name: custom_messages custom_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_messages
    ADD CONSTRAINT custom_messages_pkey PRIMARY KEY (id);


--
-- Name: custom_schedules custom_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_schedules
    ADD CONSTRAINT custom_schedules_pkey PRIMARY KEY (id);


--
-- Name: customer_payments customer_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_payments
    ADD CONSTRAINT customer_payments_pkey PRIMARY KEY (id);


--
-- Name: customer_ticket_consumers customer_ticket_consumers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_ticket_consumers
    ADD CONSTRAINT customer_ticket_consumers_pkey PRIMARY KEY (id);


--
-- Name: customer_tickets customer_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_tickets
    ADD CONSTRAINT customer_tickets_pkey PRIMARY KEY (id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: episodes episodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.episodes
    ADD CONSTRAINT episodes_pkey PRIMARY KEY (id);


--
-- Name: equipments equipments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipments
    ADD CONSTRAINT equipments_pkey PRIMARY KEY (id);


--
-- Name: filtered_outcomes filtered_outcomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filtered_outcomes
    ADD CONSTRAINT filtered_outcomes_pkey PRIMARY KEY (id);


--
-- Name: function_accesses function_accesses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.function_accesses
    ADD CONSTRAINT function_accesses_pkey PRIMARY KEY (id);


--
-- Name: lessons lessons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lessons
    ADD CONSTRAINT lessons_pkey PRIMARY KEY (id);


--
-- Name: line_notice_charges line_notice_charges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.line_notice_charges
    ADD CONSTRAINT line_notice_charges_pkey PRIMARY KEY (id);


--
-- Name: line_notice_requests line_notice_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.line_notice_requests
    ADD CONSTRAINT line_notice_requests_pkey PRIMARY KEY (id);


--
-- Name: menu_categories menu_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_categories
    ADD CONSTRAINT menu_categories_pkey PRIMARY KEY (id);


--
-- Name: menu_equipments menu_equipments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_equipments
    ADD CONSTRAINT menu_equipments_pkey PRIMARY KEY (id);


--
-- Name: menu_reservation_setting_rules menu_reservation_setting_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_reservation_setting_rules
    ADD CONSTRAINT menu_reservation_setting_rules_pkey PRIMARY KEY (id);


--
-- Name: menus menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: online_service_customer_relations online_service_customer_relations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_service_customer_relations
    ADD CONSTRAINT online_service_customer_relations_pkey PRIMARY KEY (id);


--
-- Name: online_services online_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_services
    ADD CONSTRAINT online_services_pkey PRIMARY KEY (id);


--
-- Name: payment_withdrawals payment_withdrawals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_withdrawals
    ADD CONSTRAINT payment_withdrawals_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: pghero_query_stats pghero_query_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pghero_query_stats
    ADD CONSTRAINT pghero_query_stats_pkey PRIMARY KEY (id);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: product_requirements product_requirements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_requirements
    ADD CONSTRAINT product_requirements_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: query_filters query_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query_filters
    ADD CONSTRAINT query_filters_pkey PRIMARY KEY (id);


--
-- Name: question_answers question_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_answers
    ADD CONSTRAINT question_answers_pkey PRIMARY KEY (id);


--
-- Name: ranks ranks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ranks
    ADD CONSTRAINT ranks_pkey PRIMARY KEY (id);


--
-- Name: referral_credits referral_credits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_credits
    ADD CONSTRAINT referral_credits_pkey PRIMARY KEY (id);


--
-- Name: referrals referrals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_pkey PRIMARY KEY (id);


--
-- Name: reservation_booking_options reservation_booking_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_booking_options
    ADD CONSTRAINT reservation_booking_options_pkey PRIMARY KEY (id);


--
-- Name: reservation_customers reservation_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_customers
    ADD CONSTRAINT reservation_customers_pkey PRIMARY KEY (id);


--
-- Name: reservation_menus reservation_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_menus
    ADD CONSTRAINT reservation_menus_pkey PRIMARY KEY (id);


--
-- Name: reservation_setting_menus reservation_setting_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_setting_menus
    ADD CONSTRAINT reservation_setting_menus_pkey PRIMARY KEY (id);


--
-- Name: reservation_settings reservation_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_settings
    ADD CONSTRAINT reservation_settings_pkey PRIMARY KEY (id);


--
-- Name: reservation_staffs reservation_staffs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_staffs
    ADD CONSTRAINT reservation_staffs_pkey PRIMARY KEY (id);


--
-- Name: reservations reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (id);


--
-- Name: sale_pages sale_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_pages
    ADD CONSTRAINT sale_pages_pkey PRIMARY KEY (id);


--
-- Name: sale_templates sale_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_templates
    ADD CONSTRAINT sale_templates_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: shop_menu_repeating_dates shop_menu_repeating_dates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_menu_repeating_dates
    ADD CONSTRAINT shop_menu_repeating_dates_pkey PRIMARY KEY (id);


--
-- Name: shop_menus shop_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_menus
    ADD CONSTRAINT shop_menus_pkey PRIMARY KEY (id);


--
-- Name: shop_staffs shop_staffs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_staffs
    ADD CONSTRAINT shop_staffs_pkey PRIMARY KEY (id);


--
-- Name: shops shops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shops
    ADD CONSTRAINT shops_pkey PRIMARY KEY (id);


--
-- Name: social_accounts social_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_accounts
    ADD CONSTRAINT social_accounts_pkey PRIMARY KEY (id);


--
-- Name: social_customers social_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_customers
    ADD CONSTRAINT social_customers_pkey PRIMARY KEY (id);


--
-- Name: social_messages social_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_messages
    ADD CONSTRAINT social_messages_pkey PRIMARY KEY (id);


--
-- Name: social_rich_menus social_rich_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_rich_menus
    ADD CONSTRAINT social_rich_menus_pkey PRIMARY KEY (id);


--
-- Name: social_user_messages social_user_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_user_messages
    ADD CONSTRAINT social_user_messages_pkey PRIMARY KEY (id);


--
-- Name: social_users social_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_users
    ADD CONSTRAINT social_users_pkey PRIMARY KEY (id);


--
-- Name: staff_accounts staff_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_accounts
    ADD CONSTRAINT staff_accounts_pkey PRIMARY KEY (id);


--
-- Name: staff_contact_group_relations staff_contact_group_relations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_contact_group_relations
    ADD CONSTRAINT staff_contact_group_relations_pkey PRIMARY KEY (id);


--
-- Name: staff_menus staff_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_menus
    ADD CONSTRAINT staff_menus_pkey PRIMARY KEY (id);


--
-- Name: staffs staffs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staffs
    ADD CONSTRAINT staffs_pkey PRIMARY KEY (id);


--
-- Name: subscription_charges subscription_charges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_charges
    ADD CONSTRAINT subscription_charges_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: survey_activities survey_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_activities
    ADD CONSTRAINT survey_activities_pkey PRIMARY KEY (id);


--
-- Name: survey_activity_slots survey_activity_slots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_activity_slots
    ADD CONSTRAINT survey_activity_slots_pkey PRIMARY KEY (id);


--
-- Name: survey_options survey_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_options
    ADD CONSTRAINT survey_options_pkey PRIMARY KEY (id);


--
-- Name: survey_questions survey_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_questions
    ADD CONSTRAINT survey_questions_pkey PRIMARY KEY (id);


--
-- Name: survey_responses survey_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_responses
    ADD CONSTRAINT survey_responses_pkey PRIMARY KEY (id);


--
-- Name: surveys surveys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.surveys
    ADD CONSTRAINT surveys_pkey PRIMARY KEY (id);


--
-- Name: taggings taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: ticket_products ticket_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_products
    ADD CONSTRAINT ticket_products_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: user_metrics user_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_metrics
    ADD CONSTRAINT user_metrics_pkey PRIMARY KEY (id);


--
-- Name: user_settings user_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_settings
    ADD CONSTRAINT user_settings_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: web_push_subscriptions web_push_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_push_subscriptions
    ADD CONSTRAINT web_push_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: booking_page_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX booking_page_index ON public.booking_pages USING btree (user_id, deleted_at, draft);


--
-- Name: consultant_account_phone_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX consultant_account_phone_index ON public.consultant_accounts USING btree (consultant_user_id, phone_number);


--
-- Name: consultant_account_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX consultant_account_token_index ON public.consultant_accounts USING btree (token);


--
-- Name: contact_groups_google_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX contact_groups_google_index ON public.contact_groups USING btree (user_id, google_uid, google_group_id, backup_google_group_id);


--
-- Name: current_rich_menu; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX current_rich_menu ON public.social_rich_menus USING btree (social_account_id, current);


--
-- Name: custom_message_social_user_messages_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX custom_message_social_user_messages_index ON public.social_user_messages USING btree (social_user_id, custom_message_id);


--
-- Name: customer_names_on_first_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX customer_names_on_first_name_idx ON public.customers USING gin (first_name public.gin_trgm_ops);


--
-- Name: customer_names_on_last_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX customer_names_on_last_name_idx ON public.customers USING gin (last_name public.gin_trgm_ops);


--
-- Name: customer_names_on_phonetic_first_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX customer_names_on_phonetic_first_name_idx ON public.customers USING gin (phonetic_first_name public.gin_trgm_ops);


--
-- Name: customer_names_on_phonetic_last_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX customer_names_on_phonetic_last_name_idx ON public.customers USING gin (phonetic_last_name public.gin_trgm_ops);


--
-- Name: customers_basic_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX customers_basic_index ON public.customers USING btree (user_id, contact_group_id, deleted_at);


--
-- Name: customers_google_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX customers_google_index ON public.customers USING btree (user_id, google_uid, google_contact_id);


--
-- Name: default_rich_menu; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX default_rich_menu ON public.social_rich_menus USING btree (social_account_id, "default");


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_priority ON public.delayed_jobs USING btree (priority, run_at);


--
-- Name: filtered_outcome_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX filtered_outcome_index ON public.filtered_outcomes USING btree (user_id, aasm_state, outcome_type, created_at);


--
-- Name: idx_reservations_on_activity_and_slot; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservations_on_activity_and_slot ON public.reservations USING btree (survey_activity_id, survey_activity_slot_id);


--
-- Name: idx_survey_responses_on_activity_and_owner; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_survey_responses_on_activity_and_owner ON public.survey_responses USING btree (survey_activity_id, owner_type, owner_id);


--
-- Name: index_access_providers_on_provider_and_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_providers_on_provider_and_uid ON public.access_providers USING btree (provider, uid);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_ahoy_events_on_name_and_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_events_on_name_and_time ON public.ahoy_events USING btree (name, "time");


--
-- Name: index_ahoy_events_on_properties; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_events_on_properties ON public.ahoy_events USING gin (properties jsonb_path_ops);


--
-- Name: index_ahoy_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_events_on_user_id ON public.ahoy_events USING btree (user_id);


--
-- Name: index_ahoy_events_on_visit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_events_on_visit_id ON public.ahoy_events USING btree (visit_id);


--
-- Name: index_ahoy_visits_on_customer_social_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_visits_on_customer_social_user_id ON public.ahoy_visits USING btree (customer_social_user_id);


--
-- Name: index_ahoy_visits_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_visits_on_owner_id ON public.ahoy_visits USING btree (owner_id);


--
-- Name: index_ahoy_visits_on_product_type_and_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_visits_on_product_type_and_product_id ON public.ahoy_visits USING btree (product_type, product_id);


--
-- Name: index_ahoy_visits_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ahoy_visits_on_user_id ON public.ahoy_visits USING btree (user_id);


--
-- Name: index_ahoy_visits_on_visit_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ahoy_visits_on_visit_token ON public.ahoy_visits USING btree (visit_token);


--
-- Name: index_ai_faqs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ai_faqs_on_user_id ON public.ai_faqs USING btree (user_id);


--
-- Name: index_blazer_audits_on_query_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_audits_on_query_id ON public.blazer_audits USING btree (query_id);


--
-- Name: index_blazer_audits_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_audits_on_user_id ON public.blazer_audits USING btree (user_id);


--
-- Name: index_blazer_checks_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_checks_on_creator_id ON public.blazer_checks USING btree (creator_id);


--
-- Name: index_blazer_checks_on_query_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_checks_on_query_id ON public.blazer_checks USING btree (query_id);


--
-- Name: index_blazer_dashboard_queries_on_dashboard_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_dashboard_queries_on_dashboard_id ON public.blazer_dashboard_queries USING btree (dashboard_id);


--
-- Name: index_blazer_dashboard_queries_on_query_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_dashboard_queries_on_query_id ON public.blazer_dashboard_queries USING btree (query_id);


--
-- Name: index_blazer_dashboards_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_dashboards_on_creator_id ON public.blazer_dashboards USING btree (creator_id);


--
-- Name: index_blazer_queries_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blazer_queries_on_creator_id ON public.blazer_queries USING btree (creator_id);


--
-- Name: index_booking_codes_on_booking_page_id_and_uuid_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_booking_codes_on_booking_page_id_and_uuid_and_code ON public.booking_codes USING btree (booking_page_id, uuid, code);


--
-- Name: index_booking_option_menus_on_booking_option_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_option_menus_on_booking_option_id ON public.booking_option_menus USING btree (booking_option_id);


--
-- Name: index_booking_option_menus_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_option_menus_on_menu_id ON public.booking_option_menus USING btree (menu_id);


--
-- Name: index_booking_options_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_options_on_user_id ON public.booking_options USING btree (user_id);


--
-- Name: index_booking_page_options_on_booking_option_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_page_options_on_booking_option_id ON public.booking_page_options USING btree (booking_option_id);


--
-- Name: index_booking_page_options_on_booking_page_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_page_options_on_booking_page_id ON public.booking_page_options USING btree (booking_page_id);


--
-- Name: index_booking_page_special_dates_on_booking_page_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_page_special_dates_on_booking_page_id ON public.booking_page_special_dates USING btree (booking_page_id);


--
-- Name: index_booking_pages_on_rich_menu_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_pages_on_rich_menu_only ON public.booking_pages USING btree (rich_menu_only);


--
-- Name: index_booking_pages_on_shop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_booking_pages_on_shop_id ON public.booking_pages USING btree (shop_id);


--
-- Name: index_booking_pages_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_booking_pages_on_slug ON public.booking_pages USING btree (slug);


--
-- Name: index_broadcasts_on_builder; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_broadcasts_on_builder ON public.broadcasts USING btree (builder_type, builder_id);


--
-- Name: index_broadcasts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_broadcasts_on_user_id ON public.broadcasts USING btree (user_id);


--
-- Name: index_business_applications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_business_applications_on_user_id ON public.business_applications USING btree (user_id);


--
-- Name: index_business_schedules_on_booking_page_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_business_schedules_on_booking_page_id ON public.business_schedules USING btree (booking_page_id);


--
-- Name: index_categories_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_user_id ON public.categories USING btree (user_id);


--
-- Name: index_chapters_on_online_service_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chapters_on_online_service_id ON public.chapters USING btree (online_service_id);


--
-- Name: index_consultant_accounts_on_consultant_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_consultant_accounts_on_consultant_user_id ON public.consultant_accounts USING btree (consultant_user_id);


--
-- Name: index_contact_group_rankings_on_contact_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contact_group_rankings_on_contact_group_id ON public.contact_group_rankings USING btree (contact_group_id);


--
-- Name: index_contact_group_rankings_on_rank_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contact_group_rankings_on_rank_id ON public.contact_group_rankings USING btree (rank_id);


--
-- Name: index_contact_groups_on_user_id_and_bind_all; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_contact_groups_on_user_id_and_bind_all ON public.contact_groups USING btree (user_id, bind_all);


--
-- Name: index_customer_payments_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_customer_payments_on_customer_id ON public.customer_payments USING btree (customer_id);


--
-- Name: index_customer_payments_on_product_id_and_product_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_customer_payments_on_product_id_and_product_type ON public.customer_payments USING btree (product_id, product_type);


--
-- Name: index_customer_ticket; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_customer_ticket ON public.customer_ticket_consumers USING btree (customer_ticket_id, consumer_id, consumer_type);


--
-- Name: index_customer_ticket_consumers_on_consumer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_customer_ticket_consumers_on_consumer ON public.customer_ticket_consumers USING btree (consumer_type, consumer_id);


--
-- Name: index_customer_ticket_consumers_on_customer_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_customer_ticket_consumers_on_customer_ticket_id ON public.customer_ticket_consumers USING btree (customer_ticket_id);


--
-- Name: index_customer_tickets_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_customer_tickets_on_code ON public.customer_tickets USING btree (code);


--
-- Name: index_customer_tickets_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_customer_tickets_on_customer_id ON public.customer_tickets USING btree (customer_id);


--
-- Name: index_customer_tickets_on_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_customer_tickets_on_ticket_id ON public.customer_tickets USING btree (ticket_id);


--
-- Name: index_customers_on_user_id_and_customer_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_customers_on_user_id_and_customer_email ON public.customers USING btree (user_id, customer_email);


--
-- Name: index_delayed_jobs_on_signature; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_delayed_jobs_on_signature ON public.delayed_jobs USING btree (signature);


--
-- Name: index_episodes_on_online_service_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_episodes_on_online_service_id ON public.episodes USING btree (online_service_id);


--
-- Name: index_equipments_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_equipments_on_name ON public.equipments USING btree (name);


--
-- Name: index_equipments_on_shop_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_equipments_on_shop_id ON public.equipments USING btree (shop_id);


--
-- Name: index_equipments_on_shop_id_and_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_equipments_on_shop_id_and_deleted_at ON public.equipments USING btree (shop_id, deleted_at);


--
-- Name: index_function_accesses_on_content_source_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_function_accesses_on_content_source_and_date ON public.function_accesses USING btree (access_date, source_id, content);


--
-- Name: index_function_accesses_on_date_and_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_function_accesses_on_date_and_source ON public.function_accesses USING btree (access_date, source_id, source_type);


--
-- Name: index_function_accesses_on_date_and_source_and_label; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_function_accesses_on_date_and_source_and_label ON public.function_accesses USING btree (access_date, source_id, label);


--
-- Name: index_lessons_on_chapter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lessons_on_chapter_id ON public.lessons USING btree (chapter_id);


--
-- Name: index_line_notice_charges_on_line_notice_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_line_notice_charges_on_line_notice_request_id ON public.line_notice_charges USING btree (line_notice_request_id);


--
-- Name: index_line_notice_charges_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_line_notice_charges_on_order_id ON public.line_notice_charges USING btree (order_id);


--
-- Name: index_line_notice_charges_on_payment_intent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_line_notice_charges_on_payment_intent_id ON public.line_notice_charges USING btree (payment_intent_id);


--
-- Name: index_line_notice_charges_on_reservation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_line_notice_charges_on_reservation_id ON public.line_notice_charges USING btree (reservation_id);


--
-- Name: index_line_notice_charges_on_user_and_free_trial; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_line_notice_charges_on_user_and_free_trial ON public.line_notice_charges USING btree (user_id, is_free_trial);


--
-- Name: index_line_notice_charges_on_user_and_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_line_notice_charges_on_user_and_state ON public.line_notice_charges USING btree (user_id, state);


--
-- Name: index_line_notice_charges_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_line_notice_charges_on_user_id ON public.line_notice_charges USING btree (user_id);


--
-- Name: index_line_notice_requests_on_reservation_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_line_notice_requests_on_reservation_and_status ON public.line_notice_requests USING btree (reservation_id, status);


--
-- Name: index_line_notice_requests_on_reservation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_line_notice_requests_on_reservation_id ON public.line_notice_requests USING btree (reservation_id);


--
-- Name: index_line_notice_requests_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_line_notice_requests_on_user_id ON public.line_notice_requests USING btree (user_id);


--
-- Name: index_menu_categories_on_menu_id_and_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_categories_on_menu_id_and_category_id ON public.menu_categories USING btree (menu_id, category_id);


--
-- Name: index_menu_equipments_on_equipment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_equipments_on_equipment_id ON public.menu_equipments USING btree (equipment_id);


--
-- Name: index_menu_equipments_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_equipments_on_menu_id ON public.menu_equipments USING btree (menu_id);


--
-- Name: index_menu_equipments_on_menu_id_and_equipment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_menu_equipments_on_menu_id_and_equipment_id ON public.menu_equipments USING btree (menu_id, equipment_id);


--
-- Name: index_menus_on_user_id_and_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menus_on_user_id_and_deleted_at ON public.menus USING btree (user_id, deleted_at);


--
-- Name: index_notifications_on_user_id_and_charged; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_user_id_and_charged ON public.notifications USING btree (user_id, charged);


--
-- Name: index_online_services_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_online_services_on_slug ON public.online_services USING btree (slug);


--
-- Name: index_online_services_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_online_services_on_user_id ON public.online_services USING btree (user_id);


--
-- Name: index_pghero_query_stats_on_database_and_captured_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pghero_query_stats_on_database_and_captured_at ON public.pghero_query_stats USING btree (database, captured_at);


--
-- Name: index_product_requirements_on_requirement; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_requirements_on_requirement ON public.product_requirements USING btree (requirement_type, requirement_id);


--
-- Name: index_product_requirements_on_requirer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_requirements_on_requirer ON public.product_requirements USING btree (requirer_type, requirer_id);


--
-- Name: index_product_requirements_on_sale_page_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_product_requirements_on_sale_page_id ON public.product_requirements USING btree (sale_page_id);


--
-- Name: index_profiles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_profiles_on_user_id ON public.profiles USING btree (user_id);


--
-- Name: index_query_filters_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_query_filters_on_user_id ON public.query_filters USING btree (user_id);


--
-- Name: index_question_answers_on_survey_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_question_answers_on_survey_activity_id ON public.question_answers USING btree (survey_activity_id);


--
-- Name: index_question_answers_on_survey_option_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_question_answers_on_survey_option_id ON public.question_answers USING btree (survey_option_id);


--
-- Name: index_question_answers_on_survey_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_question_answers_on_survey_question_id ON public.question_answers USING btree (survey_question_id);


--
-- Name: index_question_answers_on_survey_response_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_question_answers_on_survey_response_id ON public.question_answers USING btree (survey_response_id);


--
-- Name: index_ranks_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ranks_on_user_id ON public.ranks USING btree (user_id);


--
-- Name: index_referral_credits_on_referral_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_referral_credits_on_referral_id ON public.referral_credits USING btree (referral_id);


--
-- Name: index_referral_credits_on_subscription_charge_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_referral_credits_on_subscription_charge_id ON public.referral_credits USING btree (subscription_charge_id);


--
-- Name: index_referral_credits_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_referral_credits_on_user_id ON public.referral_credits USING btree (user_id);


--
-- Name: index_referrals_on_referrer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_referrals_on_referrer_id ON public.referrals USING btree (referrer_id);


--
-- Name: index_reservation_booking_options_on_booking_option_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservation_booking_options_on_booking_option_id ON public.reservation_booking_options USING btree (booking_option_id);


--
-- Name: index_reservation_booking_options_on_reservation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservation_booking_options_on_reservation_id ON public.reservation_booking_options USING btree (reservation_id);


--
-- Name: index_reservation_customers_on_reservation_id_and_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_reservation_customers_on_reservation_id_and_customer_id ON public.reservation_customers USING btree (reservation_id, customer_id);


--
-- Name: index_reservation_customers_on_sale_page_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservation_customers_on_sale_page_id_and_created_at ON public.reservation_customers USING btree (sale_page_id, created_at);


--
-- Name: index_reservation_customers_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_reservation_customers_on_slug ON public.reservation_customers USING btree (slug);


--
-- Name: index_reservation_customers_on_survey_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservation_customers_on_survey_activity_id ON public.reservation_customers USING btree (survey_activity_id);


--
-- Name: index_reservation_menus_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservation_menus_on_menu_id ON public.reservation_menus USING btree (menu_id);


--
-- Name: index_sale_pages_on_product_type_and_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_pages_on_product_type_and_product_id ON public.sale_pages USING btree (product_type, product_id);


--
-- Name: index_sale_pages_on_sale_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_pages_on_sale_template_id ON public.sale_pages USING btree (sale_template_id);


--
-- Name: index_sale_pages_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sale_pages_on_slug ON public.sale_pages USING btree (slug);


--
-- Name: index_sale_pages_on_staff_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sale_pages_on_staff_id ON public.sale_pages USING btree (staff_id);


--
-- Name: index_shop_menu_repeating_dates_on_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shop_menu_repeating_dates_on_menu_id ON public.shop_menu_repeating_dates USING btree (menu_id);


--
-- Name: index_shop_menu_repeating_dates_on_shop_id_and_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shop_menu_repeating_dates_on_shop_id_and_menu_id ON public.shop_menu_repeating_dates USING btree (shop_id, menu_id);


--
-- Name: index_shop_menus_on_shop_id_and_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shop_menus_on_shop_id_and_menu_id ON public.shop_menus USING btree (shop_id, menu_id);


--
-- Name: index_shop_staffs_on_shop_id_and_staff_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shop_staffs_on_shop_id_and_staff_id ON public.shop_staffs USING btree (shop_id, staff_id);


--
-- Name: index_shops_on_user_id_and_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shops_on_user_id_and_deleted_at ON public.shops USING btree (user_id, deleted_at);


--
-- Name: index_social_accounts_on_user_id_and_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_social_accounts_on_user_id_and_channel_id ON public.social_accounts USING btree (user_id, channel_id);


--
-- Name: index_social_customers_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_social_customers_on_customer_id ON public.social_customers USING btree (customer_id);


--
-- Name: index_social_customers_on_social_rich_menu_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_social_customers_on_social_rich_menu_key ON public.social_customers USING btree (social_rich_menu_key);


--
-- Name: index_social_messages_on_broadcast_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_social_messages_on_broadcast_id ON public.social_messages USING btree (broadcast_id);


--
-- Name: index_social_messages_on_customer_id_and_channel; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_social_messages_on_customer_id_and_channel ON public.social_messages USING btree (customer_id, channel);


--
-- Name: index_social_messages_on_user_id_and_channel; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_social_messages_on_user_id_and_channel ON public.social_messages USING btree (user_id, channel);


--
-- Name: index_social_rich_menus_on_social_account_id_and_social_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_social_rich_menus_on_social_account_id_and_social_name ON public.social_rich_menus USING btree (social_account_id, social_name);


--
-- Name: index_social_user_messages_on_social_user_id_and_ai_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_social_user_messages_on_social_user_id_and_ai_uid ON public.social_user_messages USING btree (social_user_id, ai_uid);


--
-- Name: index_social_users_on_consultant_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_social_users_on_consultant_at ON public.social_users USING btree (consultant_at);


--
-- Name: index_social_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_social_users_on_email ON public.social_users USING btree (email);


--
-- Name: index_social_users_on_pinned_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_social_users_on_pinned_and_updated_at ON public.social_users USING btree (pinned, updated_at);


--
-- Name: index_social_users_on_social_rich_menu_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_social_users_on_social_rich_menu_key ON public.social_users USING btree (social_rich_menu_key);


--
-- Name: index_staff_accounts_on_owner_id_and_phone_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_staff_accounts_on_owner_id_and_phone_number ON public.staff_accounts USING btree (owner_id, phone_number);


--
-- Name: index_staff_accounts_on_staff_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_staff_accounts_on_staff_id ON public.staff_accounts USING btree (staff_id);


--
-- Name: index_staff_accounts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_staff_accounts_on_user_id ON public.staff_accounts USING btree (user_id);


--
-- Name: index_staff_contact_group_relations_on_contact_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_staff_contact_group_relations_on_contact_group_id ON public.staff_contact_group_relations USING btree (contact_group_id);


--
-- Name: index_staff_menus_on_staff_id_and_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_staff_menus_on_staff_id_and_menu_id ON public.staff_menus USING btree (staff_id, menu_id);


--
-- Name: index_staffs_on_user_id_and_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_staffs_on_user_id_and_deleted_at ON public.staffs USING btree (user_id, deleted_at);


--
-- Name: index_subscription_charges_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscription_charges_on_plan_id ON public.subscription_charges USING btree (plan_id);


--
-- Name: index_subscriptions_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_plan_id ON public.subscriptions USING btree (plan_id);


--
-- Name: index_subscriptions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_subscriptions_on_user_id ON public.subscriptions USING btree (user_id);


--
-- Name: index_survey_activities_on_survey_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_survey_activities_on_survey_id ON public.survey_activities USING btree (survey_id);


--
-- Name: index_survey_activities_on_survey_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_survey_activities_on_survey_question_id ON public.survey_activities USING btree (survey_question_id);


--
-- Name: index_survey_activity_slots_on_survey_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_survey_activity_slots_on_survey_activity_id ON public.survey_activity_slots USING btree (survey_activity_id);


--
-- Name: index_survey_options_on_survey_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_survey_options_on_survey_question_id ON public.survey_options USING btree (survey_question_id);


--
-- Name: index_survey_questions_on_survey_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_survey_questions_on_survey_id ON public.survey_questions USING btree (survey_id);


--
-- Name: index_survey_responses_on_owner; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_survey_responses_on_owner ON public.survey_responses USING btree (owner_type, owner_id);


--
-- Name: index_survey_responses_on_survey_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_survey_responses_on_survey_id ON public.survey_responses USING btree (survey_id);


--
-- Name: index_survey_responses_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_survey_responses_on_uuid ON public.survey_responses USING btree (uuid);


--
-- Name: index_surveys_on_owner; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_surveys_on_owner ON public.surveys USING btree (owner_type, owner_id);


--
-- Name: index_surveys_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_surveys_on_slug ON public.surveys USING btree (slug);


--
-- Name: index_surveys_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_surveys_on_user_id ON public.surveys USING btree (user_id);


--
-- Name: index_taggings_on_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_context ON public.taggings USING btree (context);


--
-- Name: index_taggings_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tag_id ON public.taggings USING btree (tag_id);


--
-- Name: index_taggings_on_taggable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable_id ON public.taggings USING btree (taggable_id);


--
-- Name: index_taggings_on_taggable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable_type ON public.taggings USING btree (taggable_type);


--
-- Name: index_taggings_on_tagger_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tagger_id ON public.taggings USING btree (tagger_id);


--
-- Name: index_taggings_on_tagger_id_and_tagger_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tagger_id_and_tagger_type ON public.taggings USING btree (tagger_id, tagger_type);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_name ON public.tags USING btree (name);


--
-- Name: index_ticket_products_on_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ticket_products_on_product ON public.ticket_products USING btree (product_type, product_id);


--
-- Name: index_ticket_products_on_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ticket_products_on_ticket_id ON public.ticket_products USING btree (ticket_id);


--
-- Name: index_tickets_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_on_user_id ON public.tickets USING btree (user_id);


--
-- Name: index_user_metrics_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_metrics_on_user_id ON public.user_metrics USING btree (user_id);


--
-- Name: index_user_settings_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_settings_on_user_id ON public.user_settings USING btree (user_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_customer_latest_activity_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_customer_latest_activity_at ON public.users USING btree (customer_latest_activity_at);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_phone_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_phone_number ON public.users USING btree (phone_number);


--
-- Name: index_users_on_public_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_public_id ON public.users USING btree (public_id);


--
-- Name: index_users_on_referral_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_referral_token ON public.users USING btree (referral_token);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON public.users USING btree (unlock_token);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: index_web_push_subscriptions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_web_push_subscriptions_on_user_id ON public.web_push_subscriptions USING btree (user_id);


--
-- Name: jp_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX jp_name_index ON public.customers USING btree (user_id, phonetic_last_name, phonetic_first_name);


--
-- Name: menu_reservation_setting_rules_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX menu_reservation_setting_rules_index ON public.menu_reservation_setting_rules USING btree (menu_id, reservation_type, start_date, end_date);


--
-- Name: message_scenario_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX message_scenario_index ON public.social_user_messages USING btree (social_user_id, scenario);


--
-- Name: online_service_relation_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX online_service_relation_index ON public.online_service_customer_relations USING btree (online_service_id, customer_id, permission_state);


--
-- Name: online_service_relation_unique_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX online_service_relation_unique_index ON public.online_service_customer_relations USING btree (online_service_id, customer_id, current);


--
-- Name: order_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX order_id_index ON public.subscription_charges USING btree (order_id);


--
-- Name: payment_receiver_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payment_receiver_index ON public.payments USING btree (receiver_id);


--
-- Name: payment_withdrawal_order_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX payment_withdrawal_order_index ON public.payment_withdrawals USING btree (order_id);


--
-- Name: payment_withdrawal_receiver_state_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payment_withdrawal_receiver_state_index ON public.payment_withdrawals USING btree (receiver_id, state, amount_cents, amount_currency);


--
-- Name: personal_schedule_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX personal_schedule_index ON public.custom_schedules USING btree (user_id, open, start_time, end_time);


--
-- Name: reservation_menu_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reservation_menu_index ON public.reservation_menus USING btree (reservation_id, menu_id);


--
-- Name: reservation_query_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reservation_query_index ON public.reservations USING btree (user_id, shop_id, aasm_state, menu_id, start_time, ready_time);


--
-- Name: reservation_setting_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reservation_setting_index ON public.reservation_settings USING btree (user_id, start_time, end_time, day_type, days_of_week, day, nth_of_week);


--
-- Name: reservation_setting_menus_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reservation_setting_menus_index ON public.reservation_setting_menus USING btree (reservation_setting_id, menu_id);


--
-- Name: reservation_staff_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reservation_staff_index ON public.reservation_staffs USING btree (reservation_id, menu_id, staff_id, prepare_time, work_start_at, work_end_at, ready_time);


--
-- Name: reservation_user_shop_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reservation_user_shop_index ON public.reservations USING btree (user_id, shop_id, deleted_at);


--
-- Name: sale_page_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_page_index ON public.sale_pages USING btree (user_id, deleted_at);


--
-- Name: sequence_message_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sequence_message_index ON public.custom_messages USING btree (service_type, service_id, scenario, after_days);


--
-- Name: shop_custom_schedules_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX shop_custom_schedules_index ON public.custom_schedules USING btree (shop_id, open, start_time, end_time);


--
-- Name: shop_working_time_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX shop_working_time_index ON public.business_schedules USING btree (shop_id, business_state, day_of_week, start_time, end_time);


--
-- Name: social_customer_unique_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX social_customer_unique_index ON public.social_customers USING btree (user_id, social_account_id, social_user_id);


--
-- Name: social_message_customer_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX social_message_customer_index ON public.social_messages USING btree (social_account_id, social_customer_id);


--
-- Name: social_user_unique_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX social_user_unique_index ON public.social_users USING btree (user_id, social_service_user_id);


--
-- Name: staff_account_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX staff_account_email_index ON public.staff_accounts USING btree (owner_id, email);


--
-- Name: staff_account_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX staff_account_token_index ON public.staff_accounts USING btree (token);


--
-- Name: staff_contact_group_unique_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX staff_contact_group_unique_index ON public.staff_contact_group_relations USING btree (staff_id, contact_group_id);


--
-- Name: staff_custom_schedules_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX staff_custom_schedules_index ON public.custom_schedules USING btree (staff_id, open, start_time, end_time);


--
-- Name: staff_working_time_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX staff_working_time_index ON public.business_schedules USING btree (shop_id, staff_id, full_time, business_state, day_of_week, start_time, end_time);


--
-- Name: state_by_staff_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX state_by_staff_id_index ON public.reservation_staffs USING btree (staff_id, state);


--
-- Name: subscription_charge_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX subscription_charge_type_index ON public.subscription_charges USING btree (((details ->> 'type'::text)));


--
-- Name: taggings_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX taggings_idx ON public.taggings USING btree (tag_id, taggable_id, taggable_type, context, tagger_id, tagger_type);


--
-- Name: taggings_idy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX taggings_idy ON public.taggings USING btree (taggable_id, taggable_type, tagger_id, context);


--
-- Name: taggings_taggable_context_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX taggings_taggable_context_idx ON public.taggings USING btree (taggable_id, taggable_type, context);


--
-- Name: unique_staff_account_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_staff_account_index ON public.staff_accounts USING btree (owner_id, user_id, active_uniqueness);


--
-- Name: used_services_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX used_services_index ON public.customers USING gin (user_id, menu_ids, online_service_ids);


--
-- Name: user_state_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_state_index ON public.subscription_charges USING btree (user_id, state);


--
-- Name: line_notice_requests fk_rails_3ed6e77951; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.line_notice_requests
    ADD CONSTRAINT fk_rails_3ed6e77951 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: line_notice_requests fk_rails_492783d81a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.line_notice_requests
    ADD CONSTRAINT fk_rails_492783d81a FOREIGN KEY (reservation_id) REFERENCES public.reservations(id);


--
-- Name: line_notice_charges fk_rails_74e0235543; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.line_notice_charges
    ADD CONSTRAINT fk_rails_74e0235543 FOREIGN KEY (reservation_id) REFERENCES public.reservations(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: taggings fk_rails_9fcd2e236b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT fk_rails_9fcd2e236b FOREIGN KEY (tag_id) REFERENCES public.tags(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: line_notice_charges fk_rails_d2d9fdb86d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.line_notice_charges
    ADD CONSTRAINT fk_rails_d2d9fdb86d FOREIGN KEY (line_notice_request_id) REFERENCES public.line_notice_requests(id);


--
-- Name: line_notice_charges fk_rails_d5b38cb785; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.line_notice_charges
    ADD CONSTRAINT fk_rails_d5b38cb785 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: profiles fk_rails_e424190865; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT fk_rails_e424190865 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: extension_before_drop; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER extension_before_drop ON ddl_command_start
   EXECUTE FUNCTION _heroku.extension_before_drop();


--
-- Name: log_create_ext; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER log_create_ext ON ddl_command_end
   EXECUTE FUNCTION _heroku.create_ext();


--
-- Name: log_drop_ext; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER log_drop_ext ON sql_drop
   EXECUTE FUNCTION _heroku.drop_ext();


--
-- Name: validate_extension; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER validate_extension ON ddl_command_end
   EXECUTE FUNCTION _heroku.validate_extension();


--
-- PostgreSQL database dump complete
--

\unrestrict famd8XepDBKW7QAzVfxqGUuLmYVKkiEwpKHQlgJZwDTL6ctwYrawjN7X3DO4kBF

SET search_path TO "$user", public, heroku_ext;

INSERT INTO "schema_migrations" (version) VALUES
('20160705120808'),
('20160705141152'),
('20160708021248'),
('20160708044201'),
('20160708081126'),
('20160711124845'),
('20160713083223'),
('20160716040038'),
('20160803123550'),
('20160804141647'),
('20160805002152'),
('20160810123145'),
('20160810124115'),
('20160830151522'),
('20160830235902'),
('20160908135552'),
('20160908140827'),
('20160912071828'),
('20160912094849'),
('20160924015503'),
('20161018154942'),
('20161024135214'),
('20161027141005'),
('20161027234643'),
('20161116133354'),
('20161211160502'),
('20161218061913'),
('20161226152244'),
('20170101060554'),
('20170101060841'),
('20170117143626'),
('20170122022230'),
('20170411092212'),
('20170509132433'),
('20170513074508'),
('20170530085552'),
('20170611060236'),
('20170611073611'),
('20170627082223'),
('20170720142102'),
('20170814061241'),
('20170821073539'),
('20170827131921'),
('20171118075544'),
('20171127134653'),
('20180413110627'),
('20180413153332'),
('20180524222348'),
('20180524222614'),
('20180524223443'),
('20180612021000'),
('20180617004311'),
('20180620074249'),
('20180823153730'),
('20180904141857'),
('20181129015015'),
('20181130012847'),
('20181212223445'),
('20181226150238'),
('20181227064220'),
('20190117090106'),
('20190214062710'),
('20190224032620'),
('20190225080604'),
('20190227040922'),
('20190304143150'),
('20190307123116'),
('20190311165617'),
('20190312140721'),
('20190313140955'),
('20190316013202'),
('20190409065338'),
('20190410073550'),
('20190420050353'),
('20190612074957'),
('20190612142854'),
('20190622101709'),
('20190623050322'),
('20190624001252'),
('20190630004604'),
('20190630055440'),
('20190707082104'),
('20190724082958'),
('20190805155207'),
('20190815150851'),
('20190815160047'),
('20190815171601'),
('20190829140951'),
('20190906143743'),
('20191208001945'),
('20191208054204'),
('20191210130536'),
('20191210150650'),
('20191211162028'),
('20191224063600'),
('20191230084048'),
('20200227084346'),
('20200302082812'),
('20200320012931'),
('20200406151509'),
('20200406152338'),
('20200407053955'),
('20200426012331'),
('20200429083046'),
('20200507011209'),
('20200512102635'),
('20200625034702'),
('20200721132204'),
('20200824140936'),
('20200914033218'),
('20200914041742'),
('20200917065312'),
('20200923093836'),
('20201019072951'),
('20201104073111'),
('20201111121423'),
('20201114011120'),
('20201214063121'),
('20201228084743'),
('20201228140930'),
('20210109234255'),
('20210111070239'),
('20210113140743'),
('20210127073815'),
('20210129122718'),
('20210202020409'),
('20210222071432'),
('20210223140239'),
('20210226134008'),
('20210311112133'),
('20210318082320'),
('20210323133210'),
('20210329094612'),
('20210331134109'),
('20210413122216'),
('20210413145402'),
('20210414010243'),
('20210416033009'),
('20210416094449'),
('20210419025345'),
('20210430052825'),
('20210505090646'),
('20210513053055'),
('20210513103250'),
('20210517044404'),
('20210524020657'),
('20210527015333'),
('20210527025229'),
('20210608032458'),
('20210610005359'),
('20210610005360'),
('20210610005361'),
('20210610005362'),
('20210610005363'),
('20210610005364'),
('20210610005365'),
('20210711140109'),
('20210718021056'),
('20210718022411'),
('20210803022747'),
('20210805020614'),
('20210830082204'),
('20210913140858'),
('20210917004005'),
('20211019053832'),
('20211019140435'),
('20211023080215'),
('20211029131328'),
('20211103225844'),
('20211206143634'),
('20211228141116'),
('20220215085728'),
('20220216154732'),
('20220223132827'),
('20220414131015'),
('20220418132425'),
('20220504105105'),
('20220518024042'),
('20220518152005'),
('20220525090941'),
('20220525134226'),
('20220530105733'),
('20220620130630'),
('20220630135202'),
('20220721135216'),
('20220726135009'),
('20220728231237'),
('20220930062805'),
('20221208151219'),
('20230116045137'),
('20230207141752'),
('20230213153853'),
('20230314135331'),
('20230408232251'),
('20230516222442'),
('20230517142813'),
('20230523072534'),
('20230523072535'),
('20230601140649'),
('20230616093508'),
('20230620094659'),
('20230621014139'),
('20230718133125'),
('20230815055914'),
('20230830144948'),
('20230926140612'),
('20231013231105'),
('20231114141536'),
('20231127020713'),
('20231206053439'),
('20231208115249'),
('20231219091457'),
('20240207081157'),
('20240221165044'),
('20240311145252'),
('20240314114811'),
('20240318014002'),
('20240412022437'),
('20240415014225'),
('20240417023711'),
('20240418151411'),
('20240425113626'),
('20240427000601'),
('20240429031029'),
('20240501021924'),
('20240530162619'),
('20240605123036'),
('20240613092742'),
('20240625093510'),
('20240729135500'),
('20240731051119'),
('20240806134248'),
('20240810133901'),
('20240812140019'),
('20240817114718'),
('20240823204505'),
('20240823213428'),
('20240826145415'),
('20240913015314'),
('20240926154657'),
('20241002201733'),
('20241008143048'),
('20241013003439'),
('20241015000936'),
('20241020232855'),
('20241024135016'),
('20241030063029'),
('20241101030752'),
('20241108231106'),
('20241108231107'),
('20241108231108'),
('20241121003446'),
('20241128194906'),
('20241129233118'),
('20241204010941'),
('20241205095949'),
('20241213072553'),
('20241217134923'),
('20241223032227'),
('20241223141736'),
('20250212163447'),
('20250218163447'),
('20250228004652'),
('20250306135657'),
('20250311141530'),
('20250405223945'),
('20250423000000'),
('20250510071219'),
('20250610000000'),
('20250611000001'),
('20250612140711'),
('20250612140730'),
('20260113031127'),
('20260113031241'),
('20260120024943');


