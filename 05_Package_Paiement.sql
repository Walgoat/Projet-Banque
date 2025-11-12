-- Auteur : HANI Sidi-Walid
-- Projet Banque PL/SQL
create or replace package pkg_paiement as
  procedure valider(p_fichier varchar2);
  procedure poster(p_fichier varchar2);
end;
/
create or replace package body pkg_paiement as
  procedure valider(p_fichier varchar2) is
  begin
    update paiement_in p set statut = case
      when p.montant<=0 then 'REFUSE'
      when not exists(select 1 from compte cd where cd.numero=p.debit_no and cd.etat='OUVERT')
        or not exists(select 1 from compte cc where cc.numero=p.credit_no and cc.etat='OUVERT') then 'REFUSE'
      else 'VALIDE' end
    where p.fichier=p_fichier and p.statut='RECU';
  end;
  procedure poster(p_fichier varchar2) is
    cursor c is
      select p.id, p.devise, p.montant, cd.id debit_id, cc.id credit_id
      from paiement_in p
      join compte cd on cd.numero=p.debit_no and cd.etat='OUVERT'
      join compte cc on cc.numero=p.credit_no and cc.etat='OUVERT'
      where p.fichier=p_fichier and p.statut='VALIDE' for update skip locked;
    t varchar2(64); l_err varchar2(200);
  begin
    for r in c loop
      t := 'PAY-'||r.id;
      merge into txn x using (select t id_txn from dual) s on (x.id_txn=s.id_txn)
      when not matched then insert(id_txn,source,type_txn,montant,devise,debit,credit,statut)
      values(t,'PAY','TRANSFERT',r.montant,r.devise,r.debit_id,r.credit_id,'VALIDE');
      begin
        pkg_comptable.virement(t,r.debit_id,r.credit_id,r.montant,r.devise);
        update paiement_in set statut='POSTE', id_txn=t where current of c;
      exception when others then
        l_err := substr(sqlerrm,1,200);
        update paiement_in set statut='RETRY', raison=l_err where current of c;
      end;
    end loop;
  end;
end;
/
