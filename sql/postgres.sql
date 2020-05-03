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

--
-- Name: project_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.project_status AS ENUM (
    'waiting',
    'running',
    'done',
    'failed'
);


ALTER TYPE public.job_status OWNER TO postgres;


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

CREATE TABLE public.jobdependencies (
    id integer NOT NULL,
    from_id integer NOT NULL,
    to_id integer NOT NULL,
    active boolean NOT NULL
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
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
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
-- Name: projectdependencies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projectdependencies (
    id integer NOT NULL,
    from_id integer NOT NULL,
    to_id integer NOT NULL,
    active boolean NOT NULL
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
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    name character varying NOT NULL,
    status public.project_status NOT NULL
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
-- Name: jobdependencies id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobdependencies ALTER COLUMN id SET DEFAULT nextval('public."jobdependencies_id_seq"'::regclass);


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
-- Name: cluster cluster_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cluster
    ADD CONSTRAINT cluster_pkey PRIMARY KEY (id);


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
-- Name: projectdependencies projectdependencies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projectdependencies
    ADD CONSTRAINT projectdependencies_pkey PRIMARY KEY (id);


--
-- Name: projects project_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT project_pkey PRIMARY KEY (id);


--
-- Name: jobdependencies from_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobdependencies
    ADD CONSTRAINT from_id_fk FOREIGN KEY (from_id) REFERENCES public.jobs(id) ON DELETE CASCADE NOT VALID;


--
-- Name: projectDependencies from_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projectdependencies
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
-- Name: jobdependencies to_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobdependencies
    ADD CONSTRAINT to_id_fk FOREIGN KEY (to_id) REFERENCES public.jobs(id) ON DELETE CASCADE NOT VALID;


--
-- Name: projectdependencies to_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projectdependencies
    ADD CONSTRAINT to_id_fk FOREIGN KEY (to_id) REFERENCES public.projects(id) ON DELETE CASCADE;


-- Lorsqu'un job passe à done, on desactive ses dep
CREATE OR REPLACE 
FUNCTION public.update_jobdependencies_when_job_done()
  RETURNS trigger AS
$$
BEGIN
  IF (NEW.status = 'done' AND NEW.status <> OLD.status) THEN
       UPDATE public.jobdependencies SET active='f' WHERE from_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION public.update_jobdependencies_when_job_done() OWNER TO postgres;

CREATE TRIGGER update_jobdependencies_when_job_done
AFTER UPDATE OF status ON public.jobs
FOR EACH ROW
EXECUTE PROCEDURE public.update_jobdependencies_when_job_done();

-- Lorsqu'un projet passe à done, on desactive ses dep
CREATE OR REPLACE 
FUNCTION public.update_projectdependencies_when_project_done()
  RETURNS trigger AS
$$
BEGIN
  IF (NEW.status = 'done' AND NEW.status <> OLD.status) THEN
       UPDATE public.projectdependencies SET active='f' WHERE from_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION public.update_projectdependencies_when_project_done() OWNER TO postgres;

CREATE TRIGGER update_projectdependencies_when_project_done
AFTER UPDATE OF status ON public.projects
FOR EACH ROW
EXECUTE PROCEDURE public.update_projectdependencies_when_project_done();

-- lorsqu'une dependance de job est modifiee, on vérifie si des jobs peuvent passer à ready
CREATE OR REPLACE 
FUNCTION public.update_job_when_jobdependency_unactivate()
  RETURNS trigger AS
$$
BEGIN
    UPDATE jobs 
    SET status='ready' 
    WHERE 
    status='waiting' 
    AND NOT EXISTS (
        SELECT * FROM public.jobdependencies AS d WHERE  jobs.id = d.to_id and d.active = 't')
    AND EXISTS (
        SELECT * FROM public.projects AS p WHERE jobs.id_project = p.id and p.status = 'running');
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION public.update_job_when_jobdependency_unactivate() OWNER TO postgres;

CREATE TRIGGER update_job_when_jobdependency_unactivate
AFTER UPDATE OF active ON public.jobdependencies
FOR EACH STATEMENT
EXECUTE PROCEDURE public.update_job_when_jobdependency_unactivate();

-- lorsqu'un projet passe à running/waiting, on vérifie si des jobs doivent passer à ready/waiting
CREATE OR REPLACE 
FUNCTION public.update_job_when_project_change()
  RETURNS trigger AS
$$
BEGIN
  IF (NEW.status = 'running' AND NEW.status <> OLD.status) THEN
       UPDATE public.jobs SET status='ready' WHERE 
       status='waiting' 
       AND id_project = NEW.id
       AND NOT EXISTS (
        SELECT * FROM public.jobdependencies AS d WHERE  jobs.id = d.to_id and d.active = 't');
  END IF;
  IF (NEW.status = 'waiting' AND NEW.status <> OLD.status) THEN
       UPDATE public.jobs SET status='waiting' WHERE 
       status='ready' 
       AND id_project = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION public.update_job_when_project_change() OWNER TO postgres;

CREATE TRIGGER update_job_when_project_change
AFTER UPDATE OF status ON public.projects
FOR EACH ROW
EXECUTE PROCEDURE public.update_job_when_project_change();

-- lorsqu'une dependance de projet est modifiée, on vérifie si des projets peuvent passer à running
CREATE OR REPLACE 
FUNCTION public.update_project_when_projectdepency_unactivate()
  RETURNS trigger AS
$$
BEGIN
    UPDATE projects 
    SET status='running' 
    WHERE 
    status='waiting' 
    AND NOT EXISTS (
        SELECT * FROM public.projectdependencies AS d WHERE  projects.id = d.to_id and d.active = 't');
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION public.update_project_when_projectdepency_unactivate() OWNER TO postgres;

CREATE TRIGGER update_project_when_projectdepency_unactivate
AFTER UPDATE OF active ON public.projectdependencies
FOR EACH STATEMENT
EXECUTE PROCEDURE public.update_project_when_projectdepency_unactivate();

-- lorsqu'un job est terminé, on vérifie si son projet est aussi terminé
CREATE OR REPLACE 
FUNCTION public.update_project_when_job_done()
  RETURNS trigger AS
$$
BEGIN
    UPDATE projects 
    SET status='done' 
    WHERE 
    status='running' 
    AND NOT EXISTS (
        SELECT * FROM public.jobs AS j WHERE  projects.id = j.id_project and j.status <> 'done');
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION public.update_project_when_job_done() OWNER TO postgres;

CREATE TRIGGER update_project_when_job_done
AFTER UPDATE OF status ON public.jobs
FOR EACH STATEMENT
EXECUTE PROCEDURE public.update_project_when_job_done();

-- lorsqu'une dépendance de projet est ajoutée, on vérifie si des projets doivent passer à waiting
CREATE OR REPLACE 
FUNCTION public.update_project_when_projectdency_inserted()
  RETURNS trigger AS
$$
BEGIN
    UPDATE projects 
    SET status='waiting' 
    WHERE 
    status='running' 
    AND EXISTS (
        SELECT * FROM public.projectdependencies AS d WHERE  projects.id = d.to_id and d.active = 't');
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION public.update_project_when_projectdency_inserted() OWNER TO postgres;

CREATE TRIGGER update_project_when_projectdency_inserted
AFTER INSERT ON public.projectdependencies
FOR EACH STATEMENT
EXECUTE PROCEDURE public.update_project_when_projectdency_inserted();

-- lorsqu'une dependance de job est ajoutée on vérifie si des jobs doivent passer à waiting
CREATE OR REPLACE 
FUNCTION public.update_job_when_jobdependency_inserted()
  RETURNS trigger AS
$$
BEGIN
    UPDATE jobs 
    SET status='waiting' 
    WHERE 
    status='ready' 
    AND EXISTS (
        SELECT * FROM public.jobdependencies AS d WHERE  jobs.id = d.to_id and d.active = 't');
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION public.update_job_when_jobdependency_inserted() OWNER TO postgres;

CREATE TRIGGER update_job_when_jobdependency_inserted
AFTER INSERT ON public.jobdependencies
FOR EACH STATEMENT
EXECUTE PROCEDURE public.update_job_when_jobdependency_inserted();

--
-- PostgreSQL database dump complete
--
