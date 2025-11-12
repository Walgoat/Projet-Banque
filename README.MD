# Banque PL/SQL — Projet Oracle
### Auteur : HANI Sidi-Walid  

---

## 🎯 Introduction

Ce projet a été réalisé dans le cadre d’un **D'une modélisation et développement d’un système bancaire** sous Oracle.  
L’objectif était de concevoir une base de données **relationnelle robuste** et des **packages PL/SQL modulaires** permettant la gestion des clients, comptes, transactions, prêts, paiements et réconciliations.  

Ce document décrit **comment j’ai répondu procéder**, en expliquant les choix techniques et les vérifications effectuées.  

---

## 🧱 1. Création du schéma relationnel

Créer toutes les tables nécessaires avec les contraintes PK, FK, NOT NULL, CHECK et UNIQUE.  

- `CLIENT` : stocke les informations personnelles (nom, prénom, adresse, téléphone, e-mail, statut KYC).  
- `COMPTE` : contient les comptes bancaires liés à chaque client.  
- `TXN` : trace les transactions internes entre comptes (débit/crédit).  
- `GL` : journal général des écritures comptables.  
- `PAIEMENT_IN` : gère les fichiers de paiements entrants.  
- `PRODUIT_PRET`, `PRET`, `ECHEANCE` : pour la gestion des prêts et échéanciers.  
- `EXT_CONF`, `RECON_EX` : pour la réconciliation interne ↔ externe.  
- `STP_ETAT` : journal de traitement automatique (Straight Through Processing).  
- `AUDIT_LOG` : historique des événements.  

Chaque table a été créée dans le fichier **`01_Schema.sql`**, en appliquant les contraintes de clé primaire, clés étrangères, index, et unicité (comme `UQ_CLIENT_EMAIL`).  

---

## 🔑 2. Contraintes et intégrité référentielle

### Objectif :
Mettre en place des contraintes d’intégrité et vérifier leur validité.  

### Conception :
J’ai utilisé des **FK** pour relier les entités principales :  
- `COMPTE.CLIENT_ID → CLIENT.ID`  
- `PRET.COMPTE_ID → COMPTE.ID`  
- `ECHEANCE.PRET_ID → PRET.ID`  
- `GL.ID_TXN → TXN.ID_TXN`  
- `PAIEMENT_IN` relié à `TXN` via `ID_TXN` lors de la validation.  

Une fois créées, j’ai vérifié leur présence :  
```sql
select constraint_name, table_name, constraint_type
from user_constraints
order by table_name;
```

---

## 💾 3. Insertion des données de démonstration

### Objectif :
Insérer des données clients, comptes, prêts et paiements pour tester les modules.  

### Conception :
Dans le fichier **`11_Donnees_Demo.sql`**, j’ai ajouté des données réalistes :  
- Clients (Durand, Bernard, Dupont...) avec adresses et e-mails.  
- Comptes associés (`AL-001`, `BO-001`, etc.) avec devises et soldes.  
- Un produit de prêt standard et un prêt actif lié au compte de Durand.  
- Des paiements entrants simulant des virements externes.  

J’ai vérifié les insertions par :  
```sql
select nom, prenom, ville from client;
select numero, solde from compte;
select * from paiement_in;
```

---

## 🧮 4. Création des vues et utilisation des jointures

### Objectif :
Créer des vues de reporting utilisant les **jointures SQL modernes (JOIN / LEFT JOIN)**.

### Conception :
J’ai créé plusieurs vues dans le fichier **`09_Reporting.sql`**, notamment :  

#### Exemple : `V_BALANCE`
Permet de visualiser le solde net de chaque compte.  
```sql
create or replace view v_balance as
select c.numero, c.devise,
       sum(case when g.dc='D' then g.montant else 0 end) as debits,
       sum(case when g.dc='C' then g.montant else 0 end) as credits,
       sum(case when g.dc='C' then g.montant else 0 end) -
       sum(case when g.dc='D' then g.montant else 0 end) as net
from compte c
left join gl g on g.compte_id = c.id
group by c.numero, c.devise;
```

J’ai aussi utilisé des **jointures internes** et **gauche** dans :
- `v_txn_detail` : jointure entre TXN, COMPTE (débit/crédit), et CLIENT.  
- `v_compte_balance` : jointure entre CLIENT et COMPTE pour afficher le solde total du client.  

---

## 💰 5. Transactions et idempotence (Package Comptable)

### Objectif :
Implémenter les virements inter-comptes et garantir qu’ils ne soient jamais doublés.

### Conception :
Dans **`03_Package_Comptable.sql`**, j’ai créé les procédures :
- `virement` : transfert sécurisé entre comptes avec mise à jour des soldes et journalisation dans `GL`.
- `frais` et `annuler` : pour les frais bancaires et les annulations.  

J’ai validé l’idempotence :
```sql
exec pkg_comptable.virement('TX-001', 1, 2, 100, 'EUR');
exec pkg_comptable.virement('TX-001', 1, 2, 100, 'EUR'); -- ne double pas
select * from gl where id_txn='TX-001';
```

---

## 💸 6. Paiements et pipeline STP

### Objectif :
Charger, valider et poster automatiquement les paiements d’un fichier.

### Conception :
Packages concernés : `pkg_paiement` et `pkg_stp`.  
- **`pkg_paiement.valider`** vérifie les numéros de compte et les montants.  
- **`pkg_paiement.poster`** génère les transactions dans `TXN`.  
- **`pkg_stp.paiement_csv`** orchestre tout le pipeline automatique.  

```sql
begin
  pkg_stp.paiement_csv('F01');
end;
/
select fichier, statut, id_txn from paiement_in;
```

---

## 🏦 7. Gestion des prêts et échéanciers

### Objectif :
Mettre en place la génération d’échéancier et le prélèvement des mensualités.

### Conception :
Dans **`06_Package_Pret.sql`**, j’ai implémenté :
- `generer_echeancier` → calcule les intérêts et mensualités.
- `prelever` → débite la mensualité et crédite le compte GL_INTERETS.
- `penalite_retard` → applique une pénalité en cas de retard.  

Test de la génération :
```sql
exec pkg_pret.generer_echeancier(1);
select * from echeance where pret_id=1;
```

---

## 🔄 8. Réconciliation interne ↔ externe

### Objectif :
Comparer les transactions internes (TXN) et externes (EXT_CONF).

### Conception :
Implémenté dans **`07_Package_Reconciliation.sql`** :
```sql
exec pkg_recon.charger('E-001','PAY-9',50);
exec pkg_recon.comparer;
select * from recon_ex;
```
Les types d’écarts identifiés :
- `ABSENT_EXT` : transaction interne non confirmée.  
- `ABSENT_INT` : transaction externe non trouvée.  
- `ECART` : différence de montant.

---

## 📊 9. Reporting global et vérifications

### Objectif :
Créer des vues synthétiques et vérifier les données consolidées.

### Conception :
J’ai produit plusieurs vues pour le reporting :
```sql
select * from v_client;
select * from v_balance order by net desc;
select * from v_txn_detail where statut='POSTE';
```
Résultat : cohérence totale entre soldes, transactions et paiements.

---

## 🧹 10. Nettoyage et maintenance

### Objectif :
Ajouter un script pour purger les données de test.

### Conception :
Le fichier **`13_Nettoyage.sql`** vide toutes les tables dans le bon ordre :
```sql
begin
  delete from gl;
  delete from paiement_in;
  delete from txn;
  delete from pret;
  delete from compte;
  delete from client;
  commit;
end;
/
```

---

## 🧠 Conclusion


✔ Création du schéma complet avec contraintes.  
✔ Jointures SQL modernes (INNER / LEFT).  
✔ Packages modulaires pour chaque domaine métier.  
✔ Données de test validées et cohérentes.  
✔ Réconciliation, audit et reporting opérationnels.  

Le résultat final est une **solution bancaire complète, stable et évolutive**, prête à être déployée sous Oracle.

---

**HANI Sidi-Walid**  
Projet PL/SQL Bancaire — Oracle 21c  
