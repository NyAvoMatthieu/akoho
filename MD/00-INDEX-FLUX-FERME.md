# Index — Inventaire et fonctionnement du projet

Analyse du code **existant**, en lecture seule. Aucun fichier du projet n'a été
modifié. Format `.md` (le « `.mg` » de la demande a été interprété comme
`.md`, convention du dossier `MD/`).

## Périmètre retenu

Sont documentés les fichiers **originaux** du dépôt. Ont été écartés, car
créés par une session de travail antérieure et sans rapport avec le code
original :

| Artefact écarté | Chemin |
| --- | --- |
| `ControlePoulet`, `Repartition`, `RepartitionFille`, `CalculAcheminement` | `arbiochem-ejb/src/java/ferme/acheminement/` |
| `Poulet`, `PouletLib` | `arbiochem-ejb/src/java/ferme/poulet/` |
| `Compartiment`, `MagasinElevage` | `arbiochem-ejb/src/java/ferme/configuration/` |
| `BonCommandeSimple`, `BonCommandeSimpleLigne`, `ProduitSimple` | `arbiochem-ejb/src/java/produit/` |
| pages `ferme/acheminement/`, `ferme/poulet/`, `ferme/configuration/compartiment/` | `arbiochem-war/web/pages/ferme/` |

Critère de sélection : date de modification du fichier ≤ 2026-10-03. Les
96 autres classes du paquet `ferme` sont toutes antérieures.

## Conclusion principale

Le projet gère **bien** tout le domaine, de la réception d'un lot jusqu'à son
rangement physique en bâtiment/parquet puis son suivi journalier. En revanche :

1. **« Mise en compartiment » n'existe pas comme concept.** Le rangement réel
   du projet est le couple `idbatiment` + `idparquet`.
2. **Le « bon de commande » n'appartient pas au domaine ferme.** La chaîne
   achats (`AS_BONDECOMMANDE` → `AS_BONDELIVRAISON` → facture) et la chaîne
   élevage (`LOT` → réception → triage) sont **deux systèmes disjoints**, sans
   aucun lien en base ni en code.
3. Il n'existe **qu'un seul** point de comptage/répartition (l'arrivée
   aéroport), pas de second point au poulailler.

Voir `MD/50-FLUX-COMMANDE-A-COMPARTIMENT.md` pour la synthèse, et
`MD/60-PROCEDURE-SAISIE-JEU-ESSAI.md` pour la traduction d'un jeu de données
réel en saisie page par page.

## Documents

| Fichier | Contenu |
| --- | --- |
| `MD/10-ARCHITECTURE-APJ.md` | Framework APJ : hiérarchie de persistance, pattern JSP, transaction |
| `MD/20-CLASES-LOT-ET-REFERENTIELS.md` | `Lot` et le référentiel des lieux `Batiment` / `Parquet` / `BatimentDetail` |
| `MD/21-CLASES-RECEPTION-AEROPORT.md` | Module `receptionaeroport` — comptage d'arrivée |
| `MD/22-CLASES-TRIAGE-BATIMENT-PARQUET.md` | Module `triageBatiment` — **le rangement effectif** |
| `MD/23-CLASES-SUIVI-ELEVAGE.md` | Suivi journalier, vaccination, transfert, pesée, aliment, programme, désinfection |
| `MD/24-CLASES-CUVOIR.md` | Couvoir et production — seconde branche, œufs à la place des poussins importés |
| `MD/30-CLASES-COMMANDE-ET-LIVRAISON.md` | Chaîne achats : BC, BL, facture, demande d'achat |
| `MD/40-PAGES-JSP-FERME.md` | Inventaire des 115 JSP du domaine ferme |
| `MD/50-FLUX-COMMANDE-A-COMPARTIMENT.md` | **Le flux réel, étape par étape**, et ce qui manque |
| `MD/60-PROCEDURE-SAISIE-JEU-ESSAI.md` | **Procédure exécutable** : pages, champs et valeurs pour un jeu de données de test |
| `MD/90-ANOMALIES-ET-LACUNES.md` | Défauts constatés dans le code original |