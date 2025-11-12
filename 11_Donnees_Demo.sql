-- Auteur : HANI Sidi-Walid
-- Projet Banque PL/SQL
alter session set nls_numeric_characters='.,';
declare
  v_al number; v_bo number; v_ch number;
  a_al number; a_bo number; a_ch number; a_glp number; a_gli number; a_glx number;
  prod_std number;
  p1 number;
begin
  begin select id into v_al from client where email='alice.durand@example.test';
  exception when no_data_found then
    insert into client(civilite,nom,prenom,date_naissance,adresse1,code_postal,ville,pays,email,telephone,kyc_statut,kyc_date)
    values('Mme','Durand','Alice',date '1990-04-12','12 av. de la République','75011','Paris','FR','alice.durand@example.test','+33611112222','OK',sysdate)
    returning id into v_al; end;

  begin select id into v_bo from client where email='bob.martin@example.test';
  exception when no_data_found then
    insert into client(civilite,nom,prenom,date_naissance,adresse1,code_postal,ville,pays,email,telephone,kyc_statut,kyc_date)
    values('M','Martin','Bob',date '1988-07-01','5 rue des Lilas','69003','Lyon','FR','bob.martin@example.test','+33633334444','OK',sysdate)
    returning id into v_bo; end;

  begin select id into v_ch from client where email='charlie.bernard@example.test';
  exception when no_data_found then
    insert into client(civilite,nom,prenom,date_naissance,adresse1,code_postal,ville,pays,email,telephone,kyc_statut,kyc_date)
    values('M','Bernard','Charlie',date '1995-02-20','24 bd Victor','13008','Marseille','FR','charlie.bernard@example.test','+33655556666','OK',sysdate)
    returning id into v_ch; end;

  begin select id into a_al from compte where numero='AL-001';
  exception when no_data_found then insert into compte(client_id,numero,devise,solde,etat) values(v_al,'AL-001','EUR',2000,'OUVERT') returning id into a_al; end;
  begin select id into a_bo from compte where numero='BO-001';
  exception when no_data_found then insert into compte(client_id,numero,devise,solde,etat) values(v_bo,'BO-001','EUR',300,'OUVERT') returning id into a_bo; end;
  begin select id into a_ch from compte where numero='CH-001';
  exception when no_data_found then insert into compte(client_id,numero,devise,solde,etat) values(v_ch,'CH-001','EUR',50,'OUVERT') returning id into a_ch; end;
  begin select id into a_glp from compte where numero='GL_PRET';
  exception when no_data_found then insert into compte(client_id,numero,devise,solde,etat) values(v_al,'GL_PRET','EUR',0,'OUVERT') returning id into a_glp; end;
  begin select id into a_gli from compte where numero='GL_INTERETS';
  exception when no_data_found then insert into compte(client_id,numero,devise,solde,etat) values(v_al,'GL_INTERETS','EUR',0,'OUVERT') returning id into a_gli; end;
  begin select id into a_glx from compte where numero='GL_PENALITES';
  exception when no_data_found then insert into compte(client_id,numero,devise,solde,etat) values(v_al,'GL_PENALITES','EUR',0,'OUVERT') returning id into a_glx; end;

  begin select id into prod_std from produit_pret where nom='PretStd';
  exception when no_data_found then insert into produit_pret(nom,taux,frequence,duree_mois) values('PretStd',0.12,'MENSUEL',12) returning id into prod_std; end;

  begin
    select id into p1 from pret where compte_id=a_al and produit_id=prod_std;
  exception when no_data_found then
    insert into pret(compte_id,produit_id,principal,taux,debut) values(a_al,prod_std,1200,0.12,trunc(sysdate)) returning id into p1;
    pkg_pret.generer_echeancier(p1);
  end;

  merge into txn x using (select 'UT-200' id_txn from dual) s on (x.id_txn=s.id_txn)
  when not matched then insert(id_txn,source,type_txn,montant,devise,debit,credit,statut) values('UT-200','CORE','TRANSFERT',15,'EUR',a_al,a_bo,'VALIDE');
  pkg_comptable.virement('UT-200',a_al,a_bo,15,'EUR');
  pkg_comptable.virement('UT-200',a_al,a_bo,15,'EUR');

  insert /*+ ignore_row_on_dupkey_index(paiement_in, UQ_PYIN) */ into paiement_in(fichier,ext_ref,debit_no,credit_no,montant,devise) values('F10','E-201','AL-001','BO-001',33,'EUR');
  insert /*+ ignore_row_on_dupkey_index(paiement_in, UQ_PYIN) */ into paiement_in(fichier,ext_ref,debit_no,credit_no,montant,devise) values('F10','E-202','AL-001','BO-001',-1,'EUR');
  pkg_stp.paiement_csv('F10');

  pkg_pret.prelever(p1,1,'EMI-1001');
  commit;
end;
/
