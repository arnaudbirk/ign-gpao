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
-- Name: job_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.job_status AS ENUM (
    'waiting',
    'ready',
    'running',
    'done',
    'failed'
);


ALTER TYPE public.job_status OWNER TO postgres;

--
-- Name: udate_jobDependency(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public."udate_jobDependency"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
  IF (NEW.status = 'done' AND NEW.status <> OLD.status) THEN
       UPDATE jobDependencies SET active='f' WHERE from_id = NEW.id;
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
        SELECT * FROM jobDependencies WHERE  jobs.id = jobDependencies.from_id and jobDependencies.active = 't');  
        -- Pas besoin de retourner un element puisqu on est sur un EACH STATEMENT
        -- c est a dire la fonction n est pas declenchee pour chaque ligne modifiee
        -- mais une fois pour toute commande modifiant la table
        -- ca peut faire une grosse difference puisqu on modifie la table avec
        -- des commandes du type : UPDATE dependencies SET active='f' WHERE from_id = NEW.id;
    RETURN NULL;
END;$$;


ALTER FUNCTION public.update_job_status() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: cluster; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cluster (
    id integer NOT NULL,
    host character varying NOT NULL,
    id_thread integer NOT NULL,
    active boolean NOT NULL,
    available boolean NOT NULL
);


ALTER TABLE public.cluster OWNER TO postgres;

--
-- Name: cluster_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cluster_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cluster_id_seq OWNER TO postgres;

--
-- Name: cluster_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cluster_id_seq OWNED BY public.cluster.id;


--
-- Name: jobDependencies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."jobDependencies" (
    id integer NOT NULL,
    from_id integer NOT NULL,
    to_id integer NOT NULL,
    active boolean NOT NULL
);


ALTER TABLE public."jobDependencies" OWNER TO postgres;

--
-- Name: jobDependencies_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."jobDependencies_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."jobDependencies_id_seq" OWNER TO postgres;

--
-- Name: jobDependencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."jobDependencies_id_seq" OWNED BY public."jobDependencies".id;


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jobs (
    id integer NOT NULL,
    name character varying NOT NULL,
    start_date date,
    end_date date,
    command character varying NOT NULL,
    status public.job_status NOT NULL,
    return_code integer,
    log character varying,
    id_project integer NOT NULL,
    id_cluster integer
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
-- Name: projectDependencies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."projectDependencies" (
    id integer NOT NULL,
    from_id integer NOT NULL,
    to_id integer NOT NULL,
    active boolean NOT NULL
);


ALTER TABLE public."projectDependencies" OWNER TO postgres;

--
-- Name: projectDependencies_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."projectDependencies_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."projectDependencies_id_seq" OWNER TO postgres;

--
-- Name: projectDependencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."projectDependencies_id_seq" OWNED BY public."projectDependencies".id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    name character varying NOT NULL
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
-- Name: cluster id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cluster ALTER COLUMN id SET DEFAULT nextval('public.cluster_id_seq'::regclass);


--
-- Name: jobDependencies id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."jobDependencies" ALTER COLUMN id SET DEFAULT nextval('public."jobDependencies_id_seq"'::regclass);


--
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- Name: projectDependencies id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."projectDependencies" ALTER COLUMN id SET DEFAULT nextval('public."projectDependencies_id_seq"'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.project_id_seq'::regclass);


--
-- Name: cluster cluster_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cluster
    ADD CONSTRAINT cluster_pkey PRIMARY KEY (id);


--
-- Name: jobDependencies jobDependencies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."jobDependencies"
    ADD CONSTRAINT "jobDependencies_pkey" PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: projectDependencies projectDependencies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."projectDependencies"
    ADD CONSTRAINT "projectDependencies_pkey" PRIMARY KEY (id);


--
-- Name: projects project_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT project_pkey PRIMARY KEY (id);


--
-- Name: jobDependencies from_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."jobDependencies"
    ADD CONSTRAINT from_id_fk FOREIGN KEY (from_id) REFERENCES public.jobs(id) ON DELETE CASCADE NOT VALID;


--
-- Name: projectDependencies from_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."projectDependencies"
    ADD CONSTRAINT from_id_fk FOREIGN KEY (from_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: jobs id_cluster_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT id_cluster_fk FOREIGN KEY (id_cluster) REFERENCES public.cluster(id) NOT VALID;


--
-- Name: jobs id_project_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT id_project_fk FOREIGN KEY (id_project) REFERENCES public.projects(id) ON DELETE CASCADE NOT VALID;


--
-- Name: jobDependencies to_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."jobDependencies"
    ADD CONSTRAINT to_id_fk FOREIGN KEY (to_id) REFERENCES public.jobs(id) ON DELETE CASCADE NOT VALID;


--
-- Name: projectDependencies to_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."projectDependencies"
    ADD CONSTRAINT to_id_fk FOREIGN KEY (to_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--
