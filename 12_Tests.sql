-- Auteur : HANI Sidi-Walid
-- Projet Banque PL/SQL
set serveroutput on
declare
  v_from number; v_to number;
  a number; b number; a2 number; b2 number; n number;
begin
  select id into v_from from compte where numero='AL-001';
  select id into v_to   from compte where numero='BO-001';
  select solde into a from compte where id=v_from;
  select solde into b from compte where id=v_to;

  merge into txn x using (select 'UT-001' id_txn from dual) s on (x.id_txn=s.id_txn)
  when not matched then
    insert(id_txn,source,type_txn,montant,devise,debit,credit,statut) values('UT-001','CORE','TRANSFERT',10,'EUR',v_from,v_to,'VALIDE');

  pkg_comptable.virement('UT-001',v_from,v_to,10,'EUR');
  pkg_comptable.virement('UT-001',v_from,v_to,10,'EUR');

  select solde into a2 from compte where id=v_from;
  select solde into b2 from compte where id=v_to;
  if (a-a2)<>10 or (b2-b)<>10 then raise_application_error(-20000,'idempotence'); end if;

  insert into paiement_in(fichier,ext_ref,debit_no,credit_no,montant,devise) values('F02','EE-1','AL-001','BO-001',12,'EUR');
  pkg_paiement.valider('F02'); pkg_paiement.poster('F02');
  select count(*) into n from paiement_in where fichier='F02' and statut='POSTE';
  if n=0 then raise_application_error(-20001,'paiement'); end if;

  begin pkg_recon.comparer; end;
  dbms_output.put_line('OK');
end;
/
