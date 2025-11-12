-- Auteur : HANI Sidi-Walid
-- Projet Banque PL/SQL
create or replace package pkg_audit as
  procedure log_evt(p_who varchar2, p_evt varchar2, p_ref varchar2, p_msg varchar2);
end;
/
create or replace package body pkg_audit as
  procedure log_evt(p_who varchar2, p_evt varchar2, p_ref varchar2, p_msg varchar2) is
  begin insert into audit_log(who,evt,ref,msg) values(p_who,p_evt,p_ref,substr(p_msg,1,4000)); end;
end;
/
