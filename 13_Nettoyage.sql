-- Auteur : HANI Sidi-Walid
-- Projet Banque PL/SQL
begin
  delete from gl;
  delete from stp_etat;
  delete from recon_ex;
  delete from ext_conf;
  delete from paiement_in;
  delete from echeance;
  delete from txn;
  delete from pret;
  delete from produit_pret;
  delete from compte where numero in ('AL-001','BO-001','CH-001','GL_PRET','GL_INTERETS','GL_PENALITES');
  delete from client where email in ('alice.durand@example.test','bob.martin@example.test','charlie.bernard@example.test');
  commit;
end;
/
