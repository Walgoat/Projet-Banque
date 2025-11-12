-- Auteur : HANI Sidi-Walid
-- Projet Banque PL/SQL
create or replace package pkg_comptable as
  procedure virement(p_txn varchar2, p_debit number, p_credit number, p_montant number, p_dev char);
  procedure frais(p_txn varchar2, p_compte number, p_montant number, p_dev char);
  procedure annuler(p_txn varchar2, p_raison varchar2);
end;
/
create or replace package body pkg_comptable as
  procedure virement(p_txn varchar2, p_debit number, p_credit number, p_montant number, p_dev char) is
    bal_from number; k number; l_err varchar2(200);
  begin
    select count(*) into k from gl where id_txn=p_txn;
    if k>0 then update txn set statut='POSTE' where id_txn=p_txn; return; end if;
    select solde into bal_from from compte where id=p_debit for update;
    if bal_from<p_montant then update txn set statut='ECHEC',raison='FONDS' where id_txn=p_txn; begin pkg_audit.log_evt('SYS','LEDGER_FAIL',p_txn,'fonds'); end; return; end if;
    update compte set solde=solde-p_montant where id=p_debit;
    update compte set solde=solde+p_montant where id=p_credit;
    insert into gl(id_txn,compte_id,montant,dc,val_dt) values(p_txn,p_debit,p_montant,'D',sysdate);
    insert into gl(id_txn,compte_id,montant,dc,val_dt) values(p_txn,p_credit,p_montant,'C',sysdate);
    update txn set statut='POSTE' where id_txn=p_txn;
  exception when others then
    l_err := substr(sqlerrm,1,200);
    update txn set statut='ECHEC',raison=l_err where id_txn=p_txn;
    begin pkg_audit.log_evt('SYS','LEDGER_EX',p_txn,l_err); end;
  end;
  procedure frais(p_txn varchar2, p_compte number, p_montant number, p_dev char) is begin virement(p_txn||'-F', p_compte, p_compte, p_montant, p_dev); end;
  procedure annuler(p_txn varchar2, p_raison varchar2) is v_from number; v_to number; v_amt number; v_dev char(3); v_new varchar2(80);
  begin
    select debit, credit, montant, devise into v_from, v_to, v_amt, v_dev from txn where id_txn = p_txn;
    v_new := p_txn||'-R';
    merge into txn x using (select v_new id_txn from dual) s on (x.id_txn = s.id_txn)
    when not matched then insert (id_txn,source,type_txn,montant,devise,debit,credit,statut,raison) values (v_new,'CORE','REVERSE',v_amt,v_dev, v_to, v_from,'VALIDE',p_raison);
    virement(v_new, v_to, v_from, v_amt, v_dev);
    update txn set statut='REVERSE' where id_txn=p_txn;
  exception when no_data_found then null; end;
end;
/
