-- Auteur : HANI Sidi-Walid
-- Projet Banque PL/SQL
begin
  dbms_scheduler.create_job(job_name=>'JOB_RECON', job_type=>'PLSQL_BLOCK',
    job_action=>'begin pkg_recon.comparer; end;', start_date=>systimestamp, repeat_interval=>'FREQ=MINUTELY;INTERVAL=30', enabled=>true);
exception when others then null;
end;
/
