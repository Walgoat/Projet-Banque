-- Auteur : HANI Sidi-Walid
-- Projet Banque PL/SQL
create or replace view v_client as
select c.id, c.civilite, c.nom, c.prenom, c.date_naissance,
       c.adresse1, c.adresse2, c.code_postal, c.ville, c.pays,
       c.email, c.telephone, c.id_national, c.type_piece, c.no_piece, c.date_exp_piece,
       c.kyc_statut, c.kyc_date, c.created_at, c.updated_at
from client c;

create or replace view v_balance as
select c.numero, c.devise,
       sum(case when g.dc='D' then g.montant else 0 end) as debits,
       sum(case when g.dc='C' then g.montant else 0 end) as credits,
       sum(case when g.dc='C' then g.montant else 0 end) - sum(case when g.dc='D' then g.montant else 0 end) as net
from compte c
left join gl g on g.compte_id = c.id
group by c.numero, c.devise;

create or replace view v_compte_balance as
select cpt.id compte_id, cl.id client_id, cl.nom, cl.prenom, cl.ville, cl.pays, cl.kyc_statut,
       cpt.numero, cpt.devise,
       nvl(sum(case when g.dc='D' then g.montant end),0) debits,
       nvl(sum(case when g.dc='C' then g.montant end),0) credits,
       nvl(sum(case when g.dc='C' then g.montant end),0)-nvl(sum(case when g.dc='D' then g.montant end),0) net
from compte cpt
join client cl on cl.id = cpt.client_id
left join gl g on g.compte_id = cpt.id
group by cpt.id, cl.id, cl.nom, cl.prenom, cl.ville, cl.pays, cl.kyc_statut, cpt.numero, cpt.devise;

create or replace view v_txn_detail as
select t.id_txn, t.source, t.type_txn, t.statut, t.raison, t.montant, t.devise,
       d.numero debit_no, cd.nom debit_nom, cd.prenom debit_prenom,
       c.numero credit_no, cc.nom credit_nom, cc.prenom credit_prenom
from txn t
join compte d on d.id = t.debit
join client cd on cd.id = d.client_id
join compte c on c.id = t.credit
join client cc on cc.id = c.client_id;

create or replace view v_txn_jour as
select trunc(sysdate) as jour, count(*) as n,
       sum(case when type_txn in ('TRANSFERT','EMI','DEBOURSE','REVERSE') then montant end) as d,
       sum(case when type_txn in ('TRANSFERT','EMI','DEBOURSE','REVERSE') then montant end) as c
from txn;
