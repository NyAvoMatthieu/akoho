# `Lot` et le referentiel des lieux

Ces classes portent les **nomenclatures** du domaine. Elles ne sont pas
« dans le flux » au sens d'une transaction, mais sans elles le flux ne peut
tourner : chaque module fait reference a un lot, un batiment, un parquet.

## 1. `ferme.lot.Lot` — la cle de voute du domaine

`arbiochem-ejb/src/java/ferme/lot/Lot.java`

| | |
| --- | --- |
| Heritage | `ClassEtat` (ligne 9) |
| Table | `LOT` (ligne 125) |
| Vue de lecture | `LOT_LIB` (`LotLib.java:8`) |
| Cle | `preparePk("LOT", "getseq_lot")` (ligne 130) |

Champs :

| Champ | Ligne | Role |
| --- | --- | --- |
| `id`, `nomlot`, `reference` | 10-12 | identite du lot |
| `dateeclosion`, `datearrivee`, `dateCloture` | 13-14 | chronologie |
| `source` | 15 | origine commerciale |
| `idferme` | 16 | ferme de rattachement |
| `idarticle` | 17 | |
| `idorigine` | 18 | |
| `idprogramme` | 19 | |
| `idSouche`, `idCategorieLot` | 19 | |

Controles, tous deux appeles depuis `createObject` (ligne 101-107) :

- `checkDates()` (ligne 176) — eclosion obligatoire, arrivee obligatoire,
  `dateeclosion <= datearrivee`.
- `checkNomLotEtReference()` (ligne 164) — nom et reference obligatoires,
  unicite du couple.

`dateCloture` existe mais n'est pas saisissable : `lot-saisie.jsp:34` ne le
propose pas, et le bouton « Cloturer » est commente (`lot-fiche.jsp:93`).

### Ce que `Lot` n'est pas

Le flux commence par `LOT`, **pas par une commande**. Aucun module ne cree de
lot depuis une livraison : `As_BonDeCommande_Fille` n'a pas de champ `idLot`, et
aucune classe du depot n'instancie `Lot` en dehors de `Lot` lui-meme.

Le lot se saisit donc a la main. C'est le point de rupture entre la chaine
achats et la chaine elevage.

## 2. `ferme.configuration.Batiment` / `BatimentDetail` — le seul referentiel qui porte un effectif

`arbiochem-ejb/src/java/ferme/configuration/Batiment.java`

| | Mere | Fille |
| --- | --- | --- |
| Classe | `Batiment` (ligne 11) | `BatimentDetail` (ligne 10) |
| Heritage | `ClassMere` | `ClassFille` |
| Table | `BATIMENT` (ligne 22) | `BATIMENTDETAIL` (ligne 22) |
| Cle | `BAT` / `GETSEQBATIMENT` (ligne 29) | `BATF` / `GETSEQBATIMENTDETAIL` (ligne 29) |
| Vue | `batiment_lib` | `batimentdetail_lib` |
| Liaison | `setLiaisonFille("idMere")` | `setLiaisonMere("idMere")` |

Champs de la mere : `id`, `idFerme`, `nomBatiment`, `surface`, `capacite`,
`densite`, `longueur`, `largeur` (lignes 12-19).

**Champs de la fille — c'est ici que le projet modelise l'occupation** :

| Champ | Ligne | Role |
| --- | --- | --- |
| `idParquet` | 13 | le parquet, unite de rangement physique |
| `surface`, `capacite`, `densite` | 14-15, 19 | caracteristiques du parquet |
| `idLot` | 16 | **le lot occupant** |
| `idSexe` | 17 | ventilation male/femelle |
| `effectif` | 18 | **l'effectif reel** |

`BatimentDetail` est la seule classe du code original qui contienne a la fois un
lieu, un lot et un effectif.

Controle, `Batiment.checkValeurEntierFille()` (lignes 133-146), appele depuis
`createObject` (ligne 129). Les trois tests sont aux lignes 143-145 :

```java
if (this.getCapacite() < sommeCapaciteFille) throw new Exception(...);
if (this.getDensite()  < sommeDensiteFille)  throw new Exception(...);
if (this.getSurface()  < sommeSurfaceFille)  throw new Exception(...);
```

### Pourquoi ce referentiel est inutilise

`configuration/batiment-saisie.jsp` masque ce qui interesserait :

```jsp
:40  affichage.Champ.setVisible(pi.getFormufle().getChampFille("capacite"), false);
:41  affichage.Champ.setVisible(pi.getFormufle().getChampFille("effectif"), false);
:44  pi.getFormufle().getChampMulitple("idLot").setVisible(false);
```

`effectif` et `idLot` ne sont donc **jamais alimentes par l'ecran d'origine**. Le
controle de capacite existe dans le code mais ne peut pas s'exercer
utilement. Le tableau de consultation `configuration/inc/batiment-details.jsp`
affiche pourtant les colonnes `surface, densite, capacite, effectif` : le
modele est prevu, l'interface ne l'alimente pas.

Consequence : **la capacite restante d'un parquet n'est geree nulle part dans le
projet d'origine.**

## 3. Nomenclatures

Toutes en `TypeObjet` : pas de classe mere, pas de fichier d'onglet.

| Classe | Table | Cle |
| --- | --- | --- |
| `Parquet` | `PARQUET` | `PRQ` / `GETSEQPARQUET` |
| `ParquetBatiment` | `PARQUET_BATIMENT_LIB` | vue, herite `TypeObjet` |
| `Eclosoir` | `ECLOSOIR` | `ECL` / `GETSEQECLOSOIR` |
| `Incubateur` | `INCUBATEUR` | `INC` / `GETSEQINCUBATEUR` |
| `QualitePoussin` | `QUALITEPOUSSIN` | `QP` / `GETSEQQUALITEPOUSSIN` |
| `Souche` | `souche` | `SOU` / `GETSEQSOUCHE` |
| `OrigineLot` | `ORIGINELOT` | `OGL` / `getseq_originelot` |
| `Vehicule` | `VEHICULE` | `VHC` / `getseq_vehicule` |

### `ParquetBatiment` — la vue qui fait le lien

`ParquetBatiment` (`ParquetBatiment.java:8`) lit `PARQUET_BATIMENT_LIB` et
n'expose qu'un champ supplementaire : `idBatiment`. C'est cette vue qui permet
la liste deroulante enchee du triage (bâtiment → parquet), le meme
`idbatiment` filtrant la liste des parquets.

## 4. `ferme.utils` — deux classes, et c'est tout

| Fichier | Contenu |
| --- | --- |
| `ConstanteFerme.java` (8 lignes) | `IDSEXEMALE = "1"` (l.4), `IDSEXEFEMELLE = "0"` (l.5), `qualiteMort = "QP000022"` (l.6), `qualiteConforme = "QP000001"` (l.7) |
| `ConfigPoids.java` (88 lignes) | lecture de la vue `CONFIGPOIDS_LIB`, `genererPlagePoids(min, max, pas)` — fourchettes de poids pour la pesee |

Les identifiants de sexes sont des chaines `"1"` et `"0"`, et non des libelles.
Les valeurs de qualite sont codees en dur dans `ConstanteFerme`, ce qui rend
le modele dependent de l'initialisation de la table `QUALITEPOUSSIN`.

Il n'existe **aucun** utilitaire de repartition dans `ferme/utils`. Le seul
affichage de repartition du projet est l'onglet
`triagebatiment/inc/triagebatimentparquet-det.jsp`.