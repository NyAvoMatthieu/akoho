# Guide : acheminement et répartition des poules pondeuses

## Périmètre

Ce guide couvre uniquement :

```text
Bon de commande
  -> réception à l’aéroport
  -> transfert vers le poulailler
  -> contrôle à l’arrivée
  -> répartition par compartiment, sexe et santé
```

La nourriture, les traitements, la ponte et la production sont hors périmètre.

## Références existantes à réutiliser

Avant de créer une classe, lire ces références :

| Besoin | Référence |
| --- | --- |
| Bon de commande maître | `arbiochem-ejb/src/java/produit/BonCommandeSimple.java` |
| Ligne de commande | `arbiochem-ejb/src/java/produit/BonCommandeSimpleLigne.java` |
| Bon de livraison fournisseur | `arbiochem-ejb/src/java/faturefournisseur/As_BonDeLivraison.java` |
| Ligne de livraison | `arbiochem-ejb/src/java/faturefournisseur/As_BonDeLivraison_Fille.java` |
| Réception de poussins maître/détail | `arbiochem-ejb/src/java/ferme/receptionaeroport/ReceptionPoussinAeroport.java` |
| Détail de réception | `arbiochem-ejb/src/java/ferme/receptionaeroport/ReceptionPoussinAeroportDetail.java` |
| Lot et état | `arbiochem-ejb/src/java/ferme/lot/Lot.java` |
| Ferme/bâtiment | `arbiochem-ejb/src/java/ferme/configuration/Batiment.java` |
| Répartition existante | `arbiochem-ejb/src/java/ferme/triageBatiment/TriageBatimentParquet.java` et `TriageBatimentParquetDetail.java` |
| Transfert d’animaux | `arbiochem-ejb/src/java/ferme/transfertpoulet/TransfertPoulet.java` et `TransfertPouletDetail.java` |
| Page de saisie maître/détails | `MD/GUIDE_PAGE_SAISIE_APJ.md` |
| Règles métier APJ | `MD/GUIDE_REGLES_METIER_PROJET_APJ.md` |

`ReceptionPoussinAeroport` contient déjà le contrôle de cohérence entre la quantité reçue du maître et la somme des détails. `TriageBatimentParquet` contient le vocabulaire sexe/qualité, mais son contrôle de somme est actuellement commenté : ne pas le copier sans le renforcer.

## Décisions métier à fixer avant le code

### 1. Un antécédent peut être un BC ou un BL

À l’aéroport, l’antécédent est le bon de commande. Au poulailler, l’antécédent est la réception précédente. Un champ unique `idBL` est donc ambigu.

Choisir l’un de ces modèles :

- recommandé : `typeAntecedent` (`BC`, `BL`, `CONTROLE`) + `idAntecedent` ;
- ou deux champs explicites : `idBc` et `idBl` avec une contrainte d’exclusivité.

Ne pas déduire le type uniquement du préfixe de l’identifiant.

### 2. La quantité théorique doit être traçable

Si une commande contient plusieurs lignes, `controle` doit référencer la ligne concernée (`idLigneAntecedent`), ou un lot/poulet précis. Ajouter au minimum `idPoulet` ou `idLigneAntecedent` si plusieurs races/sexes sont commandés.

### 3. Perdus calculés, non saisis

Pour chaque contrôle :

```text
nbPerdu = quantiteTheorique - nbVivant - nbMort
```

Refuser si `nbVivant < 0`, `nbMort < 0`, ou `nbVivant + nbMort > quantiteTheorique`. Persister `nbPerdu` uniquement comme résultat contrôlé, ou le recalculer à l’affichage.

### 4. Identité du poulet

La quantité est suivie par lot et par catégorie, pas par animal individuel. `Poulet(id, nom, race)` représente donc une catégorie/race référencée dans les lignes de commande et de contrôle, sauf décision contraire explicite.

## Classes à créer ou adapter

Les packages proposés sont indicatifs ; conserver les packages `ferme.*` déjà utilisés.

### `Poulet`

Fichier : `arbiochem-ejb/src/java/ferme/poulet/Poulet.java`

```text
id, nom, race
```

Hériter de `ClassMAPTable`, table `POULET`, PK dédiée, `getTuppleID()` et `getAttributIDName()`.

### `Magasin` ou lieu

Fichier : `arbiochem-ejb/src/java/ferme/configuration/MagasinElevage.java`

```text
id, nom, typeLieu (AEROPORT/POULAILLER), actif
```

Le projet possède déjà `magasin.Magasin`. Le réutiliser si sa sémantique convient ; sinon créer un référentiel de lieux séparé. Un lieu ne doit pas être confondu avec un compte de stock.

### `Compartiment`

Fichier : `arbiochem-ejb/src/java/ferme/configuration/Compartiment.java`

```text
id, nom, capacite, idPoulailler
```

Si le poulailler est déjà modélisé par `Ferme`, `Batiment` ou `Parquet`, utiliser le nom et la FK réellement retenus dans la base. Contrôler `qttTotaleCompartiment <= capacite`.

### `Controle`

Fichier : `arbiochem-ejb/src/java/ferme/acheminement/ControlePoulet.java`

```text
id, daty, typeAntecedent, idAntecedent, idLigneAntecedent,
idPoulet, idMagasin, quantiteTheorique, nbVivant, nbMort, nbPerdu
```

Le champ `quantiteTheorique` doit être calculé côté métier depuis l’antécédent. Ne pas accepter sa valeur venant du formulaire comme vérité. Vérifier que l’antécédent existe, que le lieu est autorisé et que le contrôle est chronologiquement cohérent.

### `Repartition` / `RepartitionFille`

Fichiers :

```text
arbiochem-ejb/src/java/ferme/acheminement/Repartition.java
arbiochem-ejb/src/java/ferme/acheminement/RepartitionFille.java
```

Maître :

```text
id, daty, idControlePoulailler ou idBL
```

Détail :

```text
id, idRepartitionMere, idCompartiment, qtt, sexe, sante
```

Le modèle doit référencer le contrôle réalisé au poulailler, pas seulement un BL si plusieurs contrôles existent pour ce BL. `sexe` est une valeur contrôlée (`MALE`, `FEMELLE`) et `sante` un nombre de `0` à `10`.

## Héritage et conventions APJ

Pour chaque objet persistant :

1. Hériter de `ClassMAPTable`, `ClassMere` ou `ClassFille`.
2. Définir `setNomTable(...)` dans le constructeur.
3. Définir la relation maître/détail (`setNomClasseFille`, `setLiaisonFille`, etc.).
4. Implémenter `getTuppleID`, `getAttributIDName` et `construirePK`.
5. Ajouter getters/setters pour chaque colonne.
6. Placer les contrôles dans `controler`, `controlerUpdate` ou `createObject` selon le besoin.
7. Enregistrer avec `UserEJB` pour conserver droits, transaction et historique.

`Repartition` doit suivre le modèle de `ReceptionPoussinAeroport` : vérifier la somme des détails avant `super.createObject(...)`. Toutes les écritures d’un maître et de ses lignes utilisent la même connexion.

## Règles métier obligatoires

### Contrôle d’un lieu

- l’antécédent existe ;
- son type est compatible avec le lieu courant ;
- sa quantité disponible est suffisante ;
- un contrôle a une date valide ;
- `nbVivant + nbMort + nbPerdu = quantiteTheorique` ;
- `nbPerdu` est calculé, jamais librement saisi ;
- un contrôle de poulailler ne peut pas dépasser les vivants réellement arrivés à l’aéroport.

### Répartition

- le contrôle référencé existe et concerne un poulailler ;
- chaque ligne possède un compartiment, un sexe, une quantité `> 0` et une santé entre `0` et `10` ;
- le compartiment appartient au poulailler du contrôle ;
- la somme des `qtt` égale `nbVivant` du contrôle poulailler ;
- la capacité disponible de chaque compartiment n’est pas dépassée ;
- une répartition validée ne peut pas être modifiée sans procédure d’annulation.

Utiliser une comparaison exacte sur des quantités entières. Si le projet conserve `double`, comparer avec une tolérance documentée, mais les poulets devraient idéalement être stockés en entier.

## Pages web à créer

Créer dans `arbiochem-war/web/pages/ferme/acheminement/` :

```text
controle-poulet-liste.jsp
controle-poulet-saisie.jsp
controle-poulet-fiche.jsp
repartition-liste.jsp
repartition-saisie.jsp
repartition-fiche.jsp
```

Créer aussi les pages de référentiel si elles n’existent pas :

```text
poulet-liste.jsp, poulet-saisie.jsp, poulet-fiche.jsp
compartiment-liste.jsp, compartiment-saisie.jsp, compartiment-fiche.jsp
```

Utiliser `PageRecherche`, `PageInsert`, `PageConsulte`, `PageInsertMultiple` et `Liste` comme dans `MD/GUIDE_PAGE_SAISIE_APJ.md`. Les formulaires doivent transmettre `acte`, `classe`, `nomtable` et `bute` selon le dispatcher existant.

## Base de données et factures

Préparer un script SQL versionné par le projet pour :

- tables et séquences des nouvelles classes ;
- clés étrangères et index sur `idAntecedent`, `idLigneAntecedent`, `idMagasin`, `idCompartiment` ;
- contraintes de domaine autant que possible ;
- vues de disponibilité par lot, sexe, lieu et compartiment.

La facture ne doit pas recréer la commande ni la livraison. Conserver les références :

```text
BC -> BL/réception -> contrôle -> répartition
BC/BL -> facture fournisseur, selon le flux comptable existant
```

Pour anticiper la facturation, conserver `idBc`, `idBcLigne`, `idBl` ou leurs équivalents dans les objets de réception. Réutiliser `FactureFournisseur`, `FactureFournisseurDetails` et les méthodes de génération existantes seulement après validation du mapping fournisseur/produit/quantité.

## Tests à créer

### Tests métier minimaux

Créer des tests dans l’emplacement de test adopté par le projet, par exemple :

```text
arbiochem-ejb/test/ferme/acheminement/
```

Cas à couvrir :

1. BC de `100` : contrôle aéroport `90` vivants, `5` morts, `5` perdus accepté.
2. Contrôle aéroport avec `90` vivants et `11` morts refusé.
3. Contrôle poulailler basé sur le contrôle aéroport : théorique `90`.
4. Antécédent inexistant ou mauvais type refusé.
5. Répartition `40 + 50 = 90` acceptée.
6. Répartition `40 + 49 = 90` refusée.
7. Quantité nulle/négative refusée.
8. Santé `-1` ou `11` refusée.
9. Compartiment d’un autre poulailler refusé.
10. Capacité dépassée refusée.
11. Échec d’une ligne : rollback du maître et de toutes les lignes.
12. Après validation : modification/suppression refusée ou procédure d’annulation appliquée.

### Tests manuels JSP

1. Créer le référentiel poulet, le lieu aéroport, le poulailler et deux compartiments.
2. Créer un BC avec au moins une ligne poulet mâle/femelle.
3. Saisir la réception aéroport et vérifier le calcul des pertes.
4. Saisir le contrôle poulailler avec l’ancien contrôle comme antécédent.
5. Répartir les vivants en plusieurs lignes sexe/compartiment/santé.
6. Vérifier la fiche, l’historique, les droits et les quantités restantes.
7. Tester un accès direct à l’URL sans droit et une double soumission.

## Commandes de vérification

Depuis la racine du projet :

```bash
ant -f build.xml compile
```

Pour reconstruire et déployer selon la configuration locale :

```bash
ant -f build.xml
```

Le second objectif dépend de WildFly et de `deploy.dir`. Vérifier la configuration avant de l’exécuter. Le projet utilise Java 8 dans `build.xml`.

## Ordre recommandé d’implémentation

1. Valider les noms métier : poulailler, bâtiment, parquet, compartiment et lieu.
2. Valider le modèle de référence BC/BL et la ligne antécédente.
3. Créer DDL, séquences et vues de disponibilité.
4. Créer les objets APJ et leurs contrôles unitaires.
5. Créer référentiels et pages de saisie.
6. Créer `ControlePoulet` puis son flux aéroport/poulailler.
7. Créer `Repartition` maître/détails et le contrôle de somme/capacité.
8. Ajouter droits, historique, états et liens vers facturation.
9. Exécuter les tests métier, puis les tests JSP et le build Ant.
