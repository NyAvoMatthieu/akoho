# Poussins importés : modifications des 4 scénarios

Ce document liste tout ce qui a été ajouté ou modifié dans le projet pour suivre des poussins importés, de la commande jusqu'à leur mise en compartiment. Il sert de référence pour relire, déployer ou reprendre ces changements.

## Le flux en 4 scénarios

```
 1. BON DE COMMANDE (BC) en EUR
      │ Viser → bouton « Livrer »
      ▼
 2. BON DE RÉCEPTION à l'aéroport (BL achat)
      quantité théorique (= commandée) = vivants + morts + perdus · lieu de réception
      │ Viser → écriture comptable des pertes (morts + perdus)
      │ « Générer Entrée de Stock » → les vivants entrent en stock
      ▼
 3. TRANSFERT vers l'usine (transfert de stock)
      quantité théorique (= vivants reçus) = arrivés + morts + perdus
      │ Viser → sortie au départ, entrée à l'usine, écriture des pertes du transport
      ▼
 4. ENTRÉE EN COMPARTIMENT (parquets des bâtiments de l'usine)
      lignes : bâtiment → parquet (vides uniquement) · sexe · quantité · santé (1 à 10)
      │ Valider → les compartiments sont remplis (effectif, sexe)
```

Sur la fiche du bon de réception, chaque bouton n'apparaît qu'à l'étape où il sert, et les onglets **Transfert** et **Entrée en compartiment** montrent ce qui a été fait.

**Écriture comptable des pertes** (scénarios 2 et 3) : journal OD, débit **671400** « Perte de stock », crédit compte de stock du produit. Le montant est (morts + perdus) × prix unitaire moyen en Ariary.

## Fichiers modifiés, par scénario

Les chemins partent de la racine du projet. Les fichiers marqués *(nouveau)* ont été créés, les autres existaient déjà.

### Scénario 1 : bon de commande en EUR
Aucun code : l'écran de bon de commande existant gère déjà la devise EUR et le taux de change par ligne.

### Scénario 2 : bon de réception à l'aéroport
| Fichier | Ce qui a changé |
|---|---|
| `arbiochem-ejb/src/java/faturefournisseur/As_BonDeLivraison.java` | Champs quantité théorique, morts, perdus, lieu de réception. Contrôle vivants + morts + perdus = théorique. Écriture des pertes au visa (`genererEcriturePerte`). Correction du point du mouvement de stock (`genereMvtStock`). |
| `arbiochem-ejb/src/java/faturefournisseur/As_BonDeLivraison_Lib.java` | Libellé du lieu de réception. |
| `arbiochem-ejb/src/java/faturefournisseur/As_BonDeCommande.java` | Quantité théorique du bon pré-remplie avec la quantité commandée. |
| `arbiochem-war/web/pages/bondelivraison/bondelivraison-arbiochem-saisie.jsp` | Nouveaux champs : théorique (lecture seule), morts, perdus, lieu de réception. |
| `arbiochem-war/web/pages/bondelivraison/bondelivraison-arbiochem-liste.jsp` | Colonnes lieu, morts, perdus et filtre par lieu. |
| `arbiochem-war/web/pages/stock/mvtstock-saisie.jsp` | Le champ Point n'est plus désactivé, il est donc bien envoyé (corrige « Champ point obligatoire »). |
| `arbiochem-ejb/src/java/apj.properties` | **Local uniquement** : connexion à la base Docker. Interdit au commit par le hook `control/pre-commit`. |

### Scénario 3 : transfert vers l'usine
| Fichier | Ce qui a changé |
|---|---|
| `arbiochem-ejb/src/java/stock/TransfertStock.java` | Champs bon lié, théorique, morts, perdus. Contrôle des quantités. La sortie inclut les morts et perdus. Écriture des pertes au visa. Mouvement source = l'entrée de stock du bon (produits FIFO, LIFO ou par lot uniquement). Un seul transfert par bon, et aucun après l'entrée en compartiment. |
| `arbiochem-ejb/src/java/stock/TransfertStockCpl.java` | Aligné sur les colonnes de la vue (le champ lieu de départ a été retiré). |
| `arbiochem-ejb/src/java/faturefournisseur/As_BonDeLivraison.java` | Transfert pré-rempli depuis le bon (`genererTransfertPourPrerempli`), mouvement source (`getMvtSourceEntree`), état du bon (`getResteAEntrerStock`, `getTransferts`, `aTransfertVise`, `checkTransfertPossible`). |
| `arbiochem-war/web/pages/stock/transfertstock/transfertstock-saisie.jsp` | Pré-remplissage depuis un bon (`?idBL=`) et nouveaux champs. |
| `arbiochem-war/web/pages/stock/transfertstock/transfertstock-fiche.jsp` | Affichage du bon lié (avec lien), du théorique, des morts et des perdus. |
| `arbiochem-war/web/pages/stock/transfertstock/transfertstock-liste.jsp` | Colonnes bon de réception, morts, perdus et filtre par bon. |
| `arbiochem-war/web/pages/bondelivraison/inc/bondelivraison-transfert.jsp` *(nouveau)* | Onglet « Transfert » de la fiche du bon : transferts du bon, dépliables. |

### Scénario 4 : entrée en compartiment
Même saisie que l'écran existant « Triage par bâtiment et par parquet », sans la qualité et avec la santé.

| Fichier | Ce qui a changé |
|---|---|
| `arbiochem-ejb/src/java/ferme/compartiment/EntreeCompartiment.java` *(nouveau)* | En-tête (date, bon, disponibles, remarque). Contrôles : bon existant et visé, transfert visé, une seule entrée par bon, bâtiment de l'usine d'arrivée, compartiment vide, capacité, total ≤ poussins arrivés. À la validation, les compartiments sont remplis. |
| `arbiochem-ejb/src/java/ferme/compartiment/EntreeCompartimentDetail.java` *(nouveau)* | Ligne : bâtiment, parquet, sexe, quantité, santé de 1 à 10 (0 = mort, refusé). |
| `arbiochem-ejb/src/java/ferme/compartiment/EntreeCompartimentLib.java` *(nouveau)* | Libellés pour la fiche et la liste. |
| `arbiochem-ejb/src/java/ferme/compartiment/EntreeCompartimentDetailLib.java` *(nouveau)* | Libellés des lignes. |
| `arbiochem-war/web/pages/ferme/compartiment/entreecompartiment-saisie.jsp` *(nouveau)* | Saisie : bâtiments de l'usine uniquement, parquets vides uniquement, santé en curseur, avertissement si aucun compartiment n'est vide. |
| `arbiochem-war/web/pages/ferme/compartiment/entreecompartiment-fiche.jsp` *(nouveau)* | Fiche avec boutons Valider / Modifier / Supprimer et onglet Détails. |
| `arbiochem-war/web/pages/ferme/compartiment/entreecompartiment-liste.jsp` *(nouveau)* | Liste des entrées. |
| `arbiochem-war/web/pages/ferme/compartiment/inc/entreecompartiment-det.jsp` *(nouveau)* | Lignes d'une entrée. |
| `arbiochem-war/web/pages/bondelivraison/inc/bondelivraison-compartiment.jsp` *(nouveau)* | Onglet « Entrée en compartiment » de la fiche du bon. |

### Commun à tous les scénarios
| Fichier | Ce qui a changé |
|---|---|
| `arbiochem-war/web/pages/bondelivraison/bondelivraison-arbiochem-fiche.jsp` | Nouveaux champs. Onglets **Transfert** et **Entrée en compartiment**. Logique des boutons : « Générer Entrée de Stock » si reste à entrer > 0 ; « Transférer vers l'usine » si stock entré, aucun transfert et pas de compartiment ; « Entrer en compartiment » si transfert visé et aucune entrée. |

## Scripts SQL (dossier `sql/`, à exécuter dans cet ordre)
| Script | Ce qu'il fait |
|---|---|
| `2026-10-03-15_35-reception-poussin-bc.sql` | Table `LIEURECEPTION` (+ « Aéroport Ivato »), 4 colonnes sur `AS_BONDELIVRAISON`, vues `AS_BONDELIVRAISON_LIB` et `_TRAITE`. |
| `2026-10-03-16_10-transfert-poussin-bl.sql` | 5 colonnes sur `TRANSFERTSTOCK`, vues `TRANSFERTSTOCKCPL` (+ `_CREE`, `_VISEE`, `_ANNULEE`). |
| `2026-10-03-18_11-entree-compartiment.sql` | Première version de l'entrée en compartiment, séquence `SEQ_ENTREECOMPARTIMENT` et entrées de menu. |
| `2026-10-04-06_20-entree-compartiment-detail.sql` | Entrée en compartiment en en-tête + lignes (remplace la première version). |
| `2026-10-04-07_30-transfert-sans-lieu-depart.sql` | Retire la colonne lieu de départ du transfert, qui n'avait pas été demandée. |
| `2026-10-04-09_00-parquet-vide.sql` | Vue des parquets vides pour la saisie. |

## Tables et objets de la base concernés

### Créés
| Objet | Rôle |
|---|---|
| `LIEURECEPTION` (table) | Lieux de réception (Aéroport Ivato). |
| `ENTREECOMPARTIMENT` (table) | En-tête des entrées en compartiment. |
| `ENTREECOMPARTIMENTDETAIL` (table) | Lignes des entrées en compartiment. |
| `SEQ_LIEURECEPTION`, `SEQ_ENTREECOMPARTIMENT`, `SEQ_ENTREECOMPARTIMENTDET` (séquences) | Numérotation. |
| `GETSEQLIEURECEPTION`, `GETSEQENTREECOMPARTIMENT`, `GETSEQENTREECOMPARTIMENTDET` (fonctions) | Identifiants utilisés par le code Java. |
| `ENTREECOMPARTIMENT_LIB`, `ENTREECOMPARTIMENTDETAIL_LIB` (vues) | Fiche, liste et onglets. |
| `PARQUET_BATIMENT_VIDE_LIB` (vue) | Parquets vides proposés à la saisie. |
| `MENUDYNAMIQUE` (3 lignes) | Menu Poussinière → Entrée en compartiment (Saisie, Liste). |

### Modifiés
| Objet | Modification |
|---|---|
| `AS_BONDELIVRAISON` | + `QTETHEORIQUE`, `QTEMORT`, `QTEPERDU`, `IDLIEURECEPTION`. |
| `TRANSFERTSTOCK` | + `IDBL`, `QTETHEORIQUE`, `QTEMORT`, `QTEPERDU`. |
| Vues `AS_BONDELIVRAISON_LIB`, `AS_BONDELIVRAISON_TRAITE` | Nouvelles colonnes du bon. |
| Vues `TRANSFERTSTOCKCPL`, `TRANSFERTSTOCKCPL_CREE`, `_VISEE`, `_ANNULEE` | Nouvelles colonnes du transfert. |

### Lus ou mis à jour par le nouveau code (structure inchangée)
| Table | Utilisation |
|---|---|
| `BATIMENTDETAIL` | Les compartiments. `EFFECTIF` et `IDSEXE` sont mis à jour à la validation d'une entrée en compartiment. |
| `BATIMENT`, `PARQUET` | Bâtiments (`IDFERME` = l'usine) et parquets. |
| `MVTSTOCK`, `MVTSTOCKFILLE` | Entrée en stock du bon, sorties et entrées des transferts. |
| `COMPTA_ECRITURE`, `COMPTA_SOUS_ECRITURE` | Écritures des pertes. |
| `PARAMCOMPTA` | Compte de perte (`PARAM001` = 671400). |
| `AS_INGREDIENTS` | `TYPESTOCK` (FIFO, CUMP…) et `COMPTE_STOCK` des produits poussins. |
| `AS_BONDECOMMANDE`, `AS_BONDECOMMANDE_FILLE` | Quantité commandée (théorique du bon). |

## Points ouverts
- **Taux EUR incohérent** en base (16 ; 10 000 ; 89 900) : à corriger avant un vrai bon de commande en euro.
- **Compte crédité pour les pertes** : `39700000` est un compte de provision (« PROV. STOCKS MARCHANDISES »). À valider avec le comptable.
- **Produits poussins sans type de stock** (Ross 308, Cobb 500, Hubbard) : leur donner FIFO ou CUMP dans la fiche produit.
- **Suppression d'une entrée en compartiment** : les lignes restent en base (lignes orphelines). Correction proposée, pas encore faite.
- **Transferts créés en double** avant la logique des boutons : `TS003413` et `TS003429` (non visés) à supprimer ou annuler.
- **Bâtiment `BAT000061` sans nom** dans l'Usine Soamahamanina : lui donner un nom dans l'écran Bâtiment.
- **Rien n'est commité** dans git. Le hook interdit `apj.properties` et `dateBuild.txt`.
