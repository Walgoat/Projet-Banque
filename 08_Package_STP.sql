-- Auteur : HANI Sidi-Walid
-- Projet Banque PL/SQL
create or replace package pkg_stp as
  procedure paiement_csv(p_fichier varchar2);
  procedure eod;
end;
/
create or replace package body pkg_stp as
  procedure paiement_csv(p_fichier varchar2) is l_err varchar2(300);
  begin
    insert into stp_etat(objet,ref,etape,statut) values('PAY','FILE:'||p_fichier,'INGEST','OK');
    pkg_paiement.valider(p_fichier);
    insert into stp_etat(objet,ref,etape,statut) values('PAY','FILE:'||p_fichier,'VALID','OK');
    pkg_paiement.poster(p_fichier);
    insert into stp_etat(objet,ref,etape,statut) values('PAY','FILE:'||p_fichier,'POST','OK');
  exception when others then
    l_err := substr(SQLERRM,1,300);
    insert into stp_etat(objet,ref,etape,statut,note) values('PAY','FILE:'||p_fichier,'ERR','KO', l_err);
  end;
  procedure eod is begin null; end;
end;
/
