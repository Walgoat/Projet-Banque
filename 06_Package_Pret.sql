-- Auteur : HANI Sidi-Walid
-- Projet Banque PL/SQL
create or replace package pkg_pret as
  procedure debourser(p_pret number, p_txn varchar2);
  procedure generer_echeancier(p_pret number);
  procedure prelever(p_pret number, p_no number, p_txn varchar2);
  procedure penalite_retard(p_pret number, p_txn varchar2, p_pct number);
end;
/
create or replace package body pkg_pret as
  procedure debourser(p_pret number, p_txn varchar2) is m number; dev char(3); acc number; gl number;
  begin
    select pr.principal, c.devise, c.id into m, dev, acc from pret pr join compte c on c.id=pr.compte_id where pr.id=p_pret;
    select id into gl from compte where numero='GL_PRET';
    insert into txn(id_txn,source,type_txn,montant,devise,debit,credit,statut) values(p_txn,'LOAN','DEBOURSE',m,dev,gl,acc,'VALIDE');
    pkg_comptable.virement(p_txn, gl, acc, m, dev);
  end;
  procedure generer_echeancier(p_pret number) is p number; n number; r number; d date; i number; intr number; prin number; m number;
  begin
    select pr.principal, pr.taux, pp.duree_mois, pr.debut into p, r, n, d from pret pr join produit_pret pp on pp.id=pr.produit_id where pr.id=p_pret;
    if n is null then n:=12; end if; if r is null then r:=0.1; end if;
    m := round((p * (r/12)) / (1 - power(1+r/12, -n)), 2);
    delete from echeance where pret_id=p_pret;
    for i in 1..n loop
      intr := round(p*(r/12),2); prin := m - intr; p := p - prin;
      insert into echeance(pret_id,no_echeance,date_echeance,principal,interet,total) values(p_pret,i,add_months(d,i),greatest(prin,0),greatest(intr,0),m);
    end loop;
  end;
  procedure prelever(p_pret number, p_no number, p_txn varchar2) is acc number; tot number; dev char(3); gl number;
  begin
    select c.id, c.devise into acc, dev from pret pr join compte c on c.id=pr.compte_id where pr.id=p_pret;
    select total into tot from echeance where pret_id=p_pret and no_echeance=p_no and statut='A_PAYER' for update;
    select id into gl from compte where numero='GL_INTERETS';
    insert into txn(id_txn,source,type_txn,montant,devise,debit,credit,statut) values(p_txn,'LOAN','EMI',tot,dev,acc,gl,'VALIDE');
    pkg_comptable.virement(p_txn,acc,gl,tot,dev);
    update echeance set statut='PAYE' where pret_id=p_pret and no_echeance=p_no;
  end;
  procedure penalite_retard(p_pret number, p_txn varchar2, p_pct number) is s number; acc number; dev char(3); gl number;
  begin
    select nvl(sum(total),0) into s from echeance where pret_id=p_pret and statut='EN_RETARD';
    if s>0 then
      select c.id, c.devise into acc, dev from pret pr join compte c on c.id=pr.compte_id where pr.id=p_pret;
      select id into gl from compte where numero='GL_PENALITES';
      insert into txn(id_txn,source,type_txn,montant,devise,debit,credit,statut) values(p_txn,'LOAN','PENALITE',round(s*p_pct,2),dev,acc,gl,'VALIDE');
      pkg_comptable.virement(p_txn,acc,gl,round(s*p_pct,2),dev);
    end if;
  end;
end;
/
