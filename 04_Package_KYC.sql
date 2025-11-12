-- Auteur : HANI Sidi-Walid
-- Projet Banque PL/SQL
create or replace package pkg_kyc as
  procedure passer_ok(p_client number);
  procedure echouer(p_client number);
end;
/
create or replace package body pkg_kyc as
  procedure passer_ok(p_client number) is begin update client set kyc_statut='OK', kyc_date=sysdate where id=p_client; end;
  procedure echouer(p_client number) is begin update client set kyc_statut='KO', kyc_date=sysdate where id=p_client; end;
end;
/
