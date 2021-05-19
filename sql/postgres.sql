--
-- PostgreSQL database dump
--

-- Dumped from database version 11.2 (Debian 11.2-1.pgdg90+1)
-- Dumped by pg_dump version 11.2 (Debian 11.2-1.pgdg90+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: session_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.session_status AS ENUM (
    'idle',
    'active',
    'idle_requested',
    'running',
    'closed'
);


ALTER TYPE public.session_status OWNER TO postgres;

--
-- Name: status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.status AS ENUM (
    'waiting',
    'ready',
    'running',
    'done',
    'failed'
);


ALTER TYPE public.status OWNER TO postgres;

--
-- Name: clean_database(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.clean_database() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  TRUNCATE table projects, sessions CASCADE;
END;
$$;


ALTER FUNCTION public.clean_database() OWNER TO postgres;

--
-- Name: clean_unused_session(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.clean_unused_session() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  nb_sessions integer;
BEGIN
  DELETE FROM sessions WHERE id IN (SELECT sessions.id
  FROM sessions
  LEFT JOIN jobs ON sessions.id = jobs.id_session
  WHERE jobs.id_session IS NULL and sessions.status = 'closed');
  GET DIAGNOSTICS nb_sessions = ROW_COUNT;
  RETURN nb_sessions;
END;
$$;


ALTER FUNCTION public.clean_unused_session() OWNER TO postgres;

--
-- Name: reinit_jobs(integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reinit_jobs(ids integer[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  nb_jobs integer;
BEGIN
  UPDATE jobs SET status = 'ready', id_session = NULL, log=NULL, return_code=NULL, start_date=NULL, end_date=NULL
  WHERE id = ANY(ids::integer[]) AND status = 'failed';
  GET DIAGNOSTICS nb_jobs = ROW_COUNT;
  RETURN nb_jobs;
END;
$$;


ALTER FUNCTION public.reinit_jobs(ids integer[]) OWNER TO postgres;

--
-- Name: set_nb_active_nodes(character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_nb_active_nodes(hostname character varying, nb_limit integer) RETURNS void
    LANGUAGE plpgsql
    AS $$

BEGIN
   UPDATE sessions SET status = (
    CASE
    WHEN status = 'idle' AND id in (SELECT id FROM sessions WHERE host=hostname AND status <> 'closed' ORDER BY id LIMIT nb_limit) THEN 'active'::session_status
    WHEN status = 'idle_requested' AND id in (SELECT id FROM sessions WHERE host=hostname AND status <> 'closed' ORDER BY id LIMIT nb_limit) THEN 'running'::session_status
    WHEN status = 'active' AND id not in (SELECT id FROM sessions WHERE host=hostname AND status <> 'closed' ORDER BY id LIMIT nb_limit) THEN 'idle'::session_status
    WHEN status = 'running' AND id not in (SELECT id FROM sessions WHERE host=hostname AND status <> 'closed' ORDER BY id LIMIT nb_limit) THEN 'idle_requested'::session_status
    ELSE status END) WHERE status <> 'closed' AND host=hostname;
END;
$$;


ALTER FUNCTION public.set_nb_active_nodes(hostname character varying, nb_limit integer) OWNER TO postgres;

--
-- Name: udate_jobDependency(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."udate_jobDependency"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
  IF (NEW.status = 'done' AND NEW.status <> OLD.status) THEN
       UPDATE jobDependencies SET active='f' WHERE upstream = NEW.id;
  END IF;
  RETURN NEW;
END;$$;


ALTER FUNCTION public."udate_jobDependency"() OWNER TO postgres;

--
-- Name: update_job_status(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_job_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
    UPDATE jobs 
    SET status='ready' 
    WHERE 
    status='waiting' 
    AND NOT EXISTS (
        SELECT * FROM jobDependencies WHERE  jobs.id = jobDependencies.upstream and jobDependencies.active = 't');  
        -- Pas besoin de retourner un element puisqu on est sur un EACH STATEMENT
        -- c est a dire la fonction n est pas declenchee pour chaque ligne modifiee
        -- mais une fois pour toute commande modifiant la table
        -- ca peut faire une grosse difference puisqu on modifie la table avec
        -- des commandes du type : UPDATE dependencies SET active='f' WHERE from_id = NEW.id;
    RETURN NULL;
END;$$;


ALTER FUNCTION public.update_job_status() OWNER TO postgres;

--
-- Name: update_job_when_jobdependency_inserted(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_job_when_jobdependency_inserted() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE jobs 
    SET status='waiting' 
    WHERE 
    status='ready' 
    AND EXISTS (
        SELECT * FROM public.jobdependencies AS d WHERE  jobs.id = d.downstream and d.active = 't');
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.update_job_when_jobdependency_inserted() OWNER TO postgres;

--
-- Name: update_job_when_jobdependency_unactivate(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_job_when_jobdependency_unactivate() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE jobs 
    SET status='ready' 
    WHERE 
    status='waiting' 
    AND NOT EXISTS (
        SELECT * FROM public.jobdependencies AS d WHERE  jobs.id = d.downstream and d.active = 't')
    AND EXISTS (
        SELECT * FROM public.projects AS p WHERE jobs.id_project = p.id and p.status = 'running');
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.update_job_when_jobdependency_unactivate() OWNER TO postgres;

--
-- Name: update_job_when_project_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_job_when_project_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (NEW.status = 'running' AND NEW.status <> OLD.status) THEN
       UPDATE public.jobs SET status='ready' WHERE 
       status='waiting' 
       AND id_project = NEW.id
       AND NOT EXISTS (
        SELECT * FROM public.jobdependencies AS d WHERE  jobs.id = d.downstream and d.active = 't');
  END IF;
  IF (NEW.status = 'waiting' AND NEW.status <> OLD.status) THEN
       UPDATE public.jobs SET status='waiting' WHERE 
       status='ready' 
       AND id_project = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_job_when_project_change() OWNER TO postgres;

--
-- Name: update_jobdependencies_when_job_done(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_jobdependencies_when_job_done() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (NEW.status = 'done' AND NEW.status <> OLD.status) THEN
       UPDATE public.jobdependencies SET active='f' WHERE upstream = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_jobdependencies_when_job_done() OWNER TO postgres;

--
-- Name: update_jobattempts_when_job_failed(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_jobattempts_when_job_failed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (NEW.status = 'failed' AND NEW.status <> OLD.status AND NEW.nb_attempts > 0) THEN
    UPDATE public.jobs SET status='ready', 
        nb_attempts = nb_attempts-1, 
        log= CONCAT(log, 
            '\nfailed with code : ', 
            CAST(return_code AS VARCHAR),
            ' in session : ',
            CAST(id_session AS VARCHAR),
            ' at ',
            CAST(end_date AS VARCHAR),
            '\n'),
        return_code = NULL,
        id_session = NULL,
        start_date = NULL,
        end_date = NULL WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_jobattempts_when_job_failed() OWNER TO postgres;

--
-- Name: update_project_when_job_done(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_project_when_job_done() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE projects 
    SET status='done' 
    WHERE 
    status='running' 
    AND NOT EXISTS (
        SELECT * FROM public.jobs AS j WHERE  projects.id = j.id_project and j.status <> 'done');
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.update_project_when_job_done() OWNER TO postgres;

--
-- Name: update_project_when_projectdency_inserted(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_project_when_projectdency_inserted() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE projects 
    SET status='waiting' 
    WHERE 
    status='running' 
    AND EXISTS (
        SELECT * FROM public.projectdependencies AS d WHERE  projects.id = d.to_id and d.active = 't');
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.update_project_when_projectdency_inserted() OWNER TO postgres;

--
-- Name: update_project_when_projectdepency_unactivate(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_project_when_projectdepency_unactivate() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE projects 
    SET status='running' 
    WHERE 
    status='waiting' 
    AND NOT EXISTS (
        SELECT * FROM public.projectdependencies AS d WHERE  projects.id = d.downstream and d.active = 't');
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.update_project_when_projectdepency_unactivate() OWNER TO postgres;

--
-- Name: update_project_when_projectdependency_inserted(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_project_when_projectdependency_inserted() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE projects 
    SET status='waiting' 
    WHERE 
    status='running' 
    AND EXISTS (
        SELECT * FROM public.projectdependencies AS d WHERE  projects.id = d.downstream and d.active = 't');
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.update_project_when_projectdependency_inserted() OWNER TO postgres;

--
-- Name: update_projectdependencies_when_project_done(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_projectdependencies_when_project_done() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (NEW.status = 'done' AND NEW.status <> OLD.status) THEN
       UPDATE public.projectdependencies SET active='f' WHERE upstream = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_projectdependencies_when_project_done() OWNER TO postgres;

--
-- Name: update_session_when_job_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_session_when_job_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (OLD.status = 'running' AND NEW.status <> OLD.status AND NEW.id_session IS NOT null) THEN
--   Dans le cas ou la session est en idle_requested il faut passer en idle
        UPDATE public.sessions SET status= CASE
            WHEN status='running'::public.session_status THEN 'active'::public.session_status
            WHEN status='idle_requested'::public.session_status THEN 'idle'::public.session_status
            END WHERE id = NEW.id_session;
  END IF;
  IF (NEW.status = 'running' AND NEW.status <> OLD.status AND NEW.id_session IS NOT null) THEN
       UPDATE public.sessions SET status='running'::public.session_status WHERE 
       id = NEW.id_session;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_session_when_job_change() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: jobdependencies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jobdependencies (
    id integer NOT NULL,
    upstream integer NOT NULL,
    downstream integer NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.jobdependencies OWNER TO postgres;

--
-- Name: jobdependencies_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.jobdependencies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.jobdependencies_id_seq OWNER TO postgres;

--
-- Name: jobdependencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.jobdependencies_id_seq OWNED BY public.jobdependencies.id;


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jobs (
    id integer NOT NULL,
    name character varying NOT NULL,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    command character varying NOT NULL,
    status public.status DEFAULT 'ready'::public.status NOT NULL,
    return_code bigint,
    log character varying,
    id_project integer NOT NULL,
    id_session integer,
    nb_attempts integer DEFAULT 1
);


ALTER TABLE public.jobs OWNER TO postgres;

--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.jobs_id_seq OWNER TO postgres;

--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    name character varying NOT NULL,
    status public.status DEFAULT 'running'::public.status NOT NULL
);


ALTER TABLE public.projects OWNER TO postgres;

--
-- Name: project_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.project_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_id_seq OWNER TO postgres;

--
-- Name: project_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.project_id_seq OWNED BY public.projects.id;


--
-- Name: projectdependencies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projectdependencies (
    id integer NOT NULL,
    upstream integer NOT NULL,
    downstream integer NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.projectdependencies OWNER TO postgres;

--
-- Name: projectdependencies_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projectdependencies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.projectdependencies_id_seq OWNER TO postgres;

--
-- Name: projectdependencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projectdependencies_id_seq OWNED BY public.projectdependencies.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sessions (
    id integer NOT NULL,
    host character varying NOT NULL,
    start_date timestamp with time zone NOT NULL,
    end_date timestamp with time zone,
    status public.session_status DEFAULT 'idle'::public.session_status NOT NULL
);


ALTER TABLE public.sessions OWNER TO postgres;

--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sessions_id_seq OWNER TO postgres;

--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: view_dependencies; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_dependencies AS
 SELECT jobdependencies.id AS dep_id,
    jobdependencies.upstream AS dep_up,
    jobdependencies.downstream AS dep_down,
    jobdependencies.active AS dep_active,
    jobs.id AS job_id,
    jobs.name AS job_name,
    jobs.start_date AS job_start_date,
    jobs.end_date AS job_end_date,
    jobs.status AS job_status,
    jobs.return_code AS jobs_return_code
   FROM (public.jobdependencies
     JOIN public.jobs ON ((jobs.id = jobdependencies.upstream)));


ALTER TABLE public.view_dependencies OWNER TO postgres;

--
-- Name: view_job; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_job AS
 SELECT jobs.id AS job_id,
    jobs.name AS job_name,
    jobs.start_date AS job_start_date,
    jobs.end_date AS job_end_date,
    jobs.command AS job_command,
    jobs.status AS job_status,
    jobs.return_code AS job_return_code,
    jobs.log AS job_log,
    jobs.nb_attempts AS job_nb_attempts,
    projects.id AS project_id,
    projects.name AS project_name,
    projects.status AS project_status,
    sessions.id AS session_id,
    sessions.host AS session_host,
    sessions.start_date AS session_start_date,
    sessions.end_date AS session_end_date,
    sessions.status AS session_status,
    to_char(jobs.start_date, 'DD-MM-YYYY'::text) AS date_debut,
    to_char(jobs.start_date::timestamptz at time zone 'UTC', 'HH24:MI:SS'::text) AS hms_debut,
    ((((((date_part('day'::text, (jobs.end_date - jobs.start_date)) * (24)::double precision) + date_part('hour'::text, (jobs.end_date - jobs.start_date))) * (60)::double precision) + date_part('minute'::text, (jobs.end_date - jobs.start_date))) * (60)::double precision) + (round((date_part('second'::text, (jobs.end_date - jobs.start_date)))::numeric, 2))::double precision) AS duree,
    to_char(jobs.end_date, 'DD-MM-YYYY'::text) AS date_fin,
    to_char(jobs.end_date::timestamptz at time zone 'UTC', 'HH24:MI:SS'::text) AS hms_fin
   FROM ((public.jobs
     JOIN public.projects ON ((projects.id = jobs.id_project)))
     LEFT JOIN public.sessions ON ((sessions.id = jobs.id_session)));


ALTER TABLE public.view_job OWNER TO postgres;

--
-- Name: view_job_status; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_job_status AS
 SELECT COALESCE(sum(
        CASE
            WHEN (jobs.status = 'ready'::public.status) THEN 1
            ELSE 0
        END), (0)::bigint) AS ready,
    COALESCE(sum(
        CASE
            WHEN (jobs.status = 'done'::public.status) THEN 1
            ELSE 0
        END), (0)::bigint) AS done,
    COALESCE(sum(
        CASE
            WHEN (jobs.status = 'waiting'::public.status) THEN 1
            ELSE 0
        END), (0)::bigint) AS waiting,
    COALESCE(sum(
        CASE
            WHEN (jobs.status = 'running'::public.status) THEN 1
            ELSE 0
        END), (0)::bigint) AS running,
    COALESCE(sum(
        CASE
            WHEN (jobs.status = 'failed'::public.status) THEN 1
            ELSE 0
        END), (0)::bigint) AS failed,
    COALESCE(sum(
        CASE
            WHEN ((jobs.status = 'failed'::public.status) OR (jobs.status = 'running'::public.status) OR (jobs.status = 'waiting'::public.status) OR (jobs.status = 'done'::public.status) OR (jobs.status = 'ready'::public.status)) THEN 1
            ELSE 0
        END), (0)::bigint) AS total
   FROM public.jobs;


ALTER TABLE public.view_job_status OWNER TO postgres;

--
-- Name: view_jobs; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_jobs AS
 SELECT jobs.id AS job_id,
    jobs.name AS job_name,
    jobs.start_date AS job_start_date,
    jobs.end_date AS job_end_date,
    jobs.command AS job_command,
    jobs.status AS job_status,
    jobs.return_code AS job_return_code,
    jobs.log AS job_log,
    jobs.id_project AS job_id_project,
    jobs.id_session AS job_session,
    projects.name AS project_name,
    to_char(jobs.start_date, 'DD-MM-YYYY'::text) AS date,
    to_char(jobs.start_date::timestamptz at time zone 'UTC', 'HH24:MI:SS'::text) AS hms,
    ((((((date_part('day'::text, (jobs.end_date - jobs.start_date)) * (24)::double precision) + date_part('hour'::text, (jobs.end_date - jobs.start_date))) * (60)::double precision) + date_part('minute'::text, (jobs.end_date - jobs.start_date))) * (60)::double precision) + (round((date_part('second'::text, (jobs.end_date - jobs.start_date)))::numeric, 2))::double precision) AS duree
   FROM (public.jobs
     JOIN public.projects ON ((projects.id = jobs.id_project)));


ALTER TABLE public.view_jobs OWNER TO postgres;

--
-- Name: view_project_status; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_project_status AS
 SELECT COALESCE(sum(
        CASE
            WHEN (projects.status = 'ready'::public.status) THEN 1
            ELSE 0
        END), (0)::bigint) AS ready,
    COALESCE(sum(
        CASE
            WHEN (projects.status = 'done'::public.status) THEN 1
            ELSE 0
        END), (0)::bigint) AS done,
    COALESCE(sum(
        CASE
            WHEN (projects.status = 'waiting'::public.status) THEN 1
            ELSE 0
        END), (0)::bigint) AS waiting,
    COALESCE(sum(
        CASE
            WHEN (projects.status = 'running'::public.status) THEN 1
            ELSE 0
        END), (0)::bigint) AS running,
    COALESCE(sum(
        CASE
            WHEN (projects.status = 'failed'::public.status) THEN 1
            ELSE 0
        END), (0)::bigint) AS failed,
    COALESCE(sum(
        CASE
            WHEN ((projects.status = 'failed'::public.status) OR (projects.status = 'running'::public.status) OR (projects.status = 'waiting'::public.status) OR (projects.status = 'done'::public.status) OR (projects.status = 'ready'::public.status)) THEN 1
            ELSE 0
        END), (0)::bigint) AS total
   FROM public.projects;


ALTER TABLE public.view_project_status OWNER TO postgres;

--
-- Name: view_project_status_by_jobs; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_project_status_by_jobs AS
 SELECT jobs.id_project,
    projects.name,
    sum(
        CASE
            WHEN (jobs.status = 'ready'::public.status) THEN 1
            ELSE 0
        END) AS ready,
    sum(
        CASE
            WHEN (jobs.status = 'done'::public.status) THEN 1
            ELSE 0
        END) AS done,
    sum(
        CASE
            WHEN (jobs.status = 'waiting'::public.status) THEN 1
            ELSE 0
        END) AS waiting,
    sum(
        CASE
            WHEN (jobs.status = 'running'::public.status) THEN 1
            ELSE 0
        END) AS running,
    sum(
        CASE
            WHEN (jobs.status = 'failed'::public.status) THEN 1
            ELSE 0
        END) AS failed,
    sum(
        CASE
            WHEN ((jobs.status = 'failed'::public.status) OR (jobs.status = 'running'::public.status) OR (jobs.status = 'waiting'::public.status) OR (jobs.status = 'done'::public.status) OR (jobs.status = 'ready'::public.status)) THEN 1
            ELSE 0
        END) AS total
   FROM (public.jobs
     JOIN public.projects ON ((projects.id = jobs.id_project)))
  GROUP BY jobs.id_project, projects.name;


ALTER TABLE public.view_project_status_by_jobs OWNER TO postgres;

--
-- Name: view_sessions; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_sessions AS
 SELECT sessions.id AS sessions_id,
    sessions.host AS sessions_host,
    sessions.start_date AS sessions_start_date,
    sessions.end_date AS sessions_end_date,
    sessions.status AS sessions_status,
    to_char(sessions.start_date, 'DD-MM-YYYY'::text) AS date_debut,
    to_char(sessions.start_date::timestamptz at time zone 'UTC', 'HH24:MI:SS'::text) AS hms_debut,
    ((((((date_part('day'::text, (sessions.end_date - sessions.start_date)) * (24)::double precision) + date_part('hour'::text, (sessions.end_date - sessions.start_date))) * (60)::double precision) + date_part('minute'::text, (sessions.end_date - sessions.start_date))) * (60)::double precision) + (round((date_part('second'::text, (sessions.end_date - sessions.start_date)))::numeric, 2))::double precision) AS duree,
    to_char(sessions.end_date, 'DD-MM-YYYY'::text) AS date_fin,
    to_char(sessions.end_date::timestamptz at time zone 'UTC', 'HH24:MI:SS'::text) AS hms_fin
   FROM public.sessions;


ALTER TABLE public.view_sessions OWNER TO postgres;

--
-- Name: view_sessions_status; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.view_sessions_status AS
 SELECT COALESCE(sum(
        CASE
            WHEN (sessions.status = 'idle'::public.session_status) THEN 1
            ELSE 0
        END), (0)::bigint) AS idle,
    COALESCE(sum(
        CASE
            WHEN (sessions.status = 'idle_requested'::public.session_status) THEN 1
            ELSE 0
        END), (0)::bigint) AS idle_requested,
    COALESCE(sum(
        CASE
            WHEN (sessions.status = 'active'::public.session_status) THEN 1
            ELSE 0
        END), (0)::bigint) AS active,
    COALESCE(sum(
        CASE
            WHEN (sessions.status = 'running'::public.session_status) THEN 1
            ELSE 0
        END), (0)::bigint) AS running,
    COALESCE(sum(
        CASE
            WHEN (sessions.status = 'closed'::public.session_status) THEN 1
            ELSE 0
        END), (0)::bigint) AS closed,
    COALESCE(sum(
        CASE
            WHEN ((sessions.status = 'idle'::public.session_status) OR (sessions.status = 'running'::public.session_status) OR (sessions.status = 'closed'::public.session_status) OR (sessions.status = 'idle_requested'::public.session_status) OR (sessions.status = 'active'::public.session_status)) THEN 1
            ELSE 0
        END), (0)::bigint) AS total
   FROM public.sessions;


ALTER TABLE public.view_sessions_status OWNER TO postgres;

--
-- Name: jobdependencies id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobdependencies ALTER COLUMN id SET DEFAULT nextval('public.jobdependencies_id_seq'::regclass);


--
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- Name: projectdependencies id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projectdependencies ALTER COLUMN id SET DEFAULT nextval('public.projectdependencies_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.project_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: jobdependencies jobdependencies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobdependencies
    ADD CONSTRAINT jobdependencies_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: projects project_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT project_pkey PRIMARY KEY (id);


--
-- Name: projectdependencies projectdependencies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projectdependencies
    ADD CONSTRAINT projectdependencies_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: jobs update_jobattempts_when_job_failed; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_jobattempts_when_job_failed AFTER UPDATE OF status ON public.jobs FOR EACH ROW EXECUTE PROCEDURE public.update_jobattempts_when_job_failed();


--
-- Name: jobdependencies update_job_when_jobdependency_inserted; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_job_when_jobdependency_inserted AFTER INSERT ON public.jobdependencies FOR EACH STATEMENT EXECUTE PROCEDURE public.update_job_when_jobdependency_inserted();


--
-- Name: jobdependencies update_job_when_jobdependency_unactivate; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_job_when_jobdependency_unactivate AFTER UPDATE OF active ON public.jobdependencies FOR EACH STATEMENT EXECUTE PROCEDURE public.update_job_when_jobdependency_unactivate();


--
-- Name: projects update_job_when_project_change; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_job_when_project_change AFTER UPDATE OF status ON public.projects FOR EACH ROW EXECUTE PROCEDURE public.update_job_when_project_change();


--
-- Name: jobs update_jobdependencies_when_job_done; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_jobdependencies_when_job_done AFTER UPDATE OF status ON public.jobs FOR EACH ROW EXECUTE PROCEDURE public.update_jobdependencies_when_job_done();


--
-- Name: jobs update_project_when_job_done; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_project_when_job_done AFTER UPDATE OF status ON public.jobs FOR EACH STATEMENT EXECUTE PROCEDURE public.update_project_when_job_done();


--
-- Name: projectdependencies update_project_when_projectdependency_inserted; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_project_when_projectdependency_inserted AFTER INSERT ON public.projectdependencies FOR EACH STATEMENT EXECUTE PROCEDURE public.update_project_when_projectdependency_inserted();


--
-- Name: projectdependencies update_project_when_projectdependency_unactivate; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_project_when_projectdependency_unactivate AFTER UPDATE OF active ON public.projectdependencies FOR EACH STATEMENT EXECUTE PROCEDURE public.update_project_when_projectdepency_unactivate();


--
-- Name: projects update_projectdependencies_when_project_done; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_projectdependencies_when_project_done AFTER UPDATE OF status ON public.projects FOR EACH ROW EXECUTE PROCEDURE public.update_projectdependencies_when_project_done();


--
-- Name: jobs update_session_when_job_change; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_session_when_job_change AFTER UPDATE OF status ON public.jobs FOR EACH ROW EXECUTE PROCEDURE public.update_session_when_job_change();


--
-- Name: jobdependencies downstream_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobdependencies
    ADD CONSTRAINT downstream_fk FOREIGN KEY (downstream) REFERENCES public.jobs(id) ON DELETE CASCADE NOT VALID;


--
-- Name: projectdependencies downstream_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projectdependencies
    ADD CONSTRAINT downstream_fk FOREIGN KEY (downstream) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: jobs id_project_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT id_project_fk FOREIGN KEY (id_project) REFERENCES public.projects(id) ON DELETE CASCADE NOT VALID;


--
-- Name: jobs id_session_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT id_session_fk FOREIGN KEY (id_session) REFERENCES public.sessions(id) NOT VALID;


--
-- Name: jobdependencies upstream_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobdependencies
    ADD CONSTRAINT upstream_fk FOREIGN KEY (upstream) REFERENCES public.jobs(id) ON DELETE CASCADE NOT VALID;


--
-- Name: projectdependencies upstream_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projectdependencies
    ADD CONSTRAINT upstream_fk FOREIGN KEY (upstream) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

