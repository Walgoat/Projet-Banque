-- Auteur : HANI Sidi-Walid
-- Projet Banque PL/SQL
create or replace package pkg_recon as
  procedure charger(p_ref varchar2, p_txn varchar2, p_mont number);
  procedure comparer;
end;
/
create or replace package body pkg_recon as
  procedure charger(p_ref varchar2, p_txn varchar2, p_mont number) is
  begin
    merge into ext_conf e using (select p_ref ref_ext, p_txn id_txn, p_mont montant from dual) s
    on (e.ref_ext=s.ref_ext)
    when not matched then insert(ref_ext,id_txn,montant) values(s.ref_ext,s.id_txn,s.montant);
  end;
  procedure comparer is
  begin
    insert into recon_ex(ref_ext,id_txn,type_ex,note)
    select null,t.id_txn,'ABSENT_EXT','ext' from txn t
    where t.statut='POSTE' and not exists(select 1 from ext_conf e where e.id_txn=t.id_txn);

    insert into recon_ex(ref_ext,id_txn,type_ex,note)
    select e.ref_ext,e.id_txn,'ABSENT_INT','int'
    from ext_conf e left join txn t on t.id_txn=e.id_txn
    where t.id_txn is null;

    insert into recon_ex(ref_ext,id_txn,type_ex,note)
    select e.ref_ext,e.id_txn,'ECART','montant'
    from ext_conf e join txn t on t.id_txn=e.id_txn
    where nvl(t.montant,0)<>nvl(e.montant,0);
  end;
end;
/
