# Anomalies et lacunes du code original

Relevé factuel, sans correction. Chaque ligne renvoie a un fichier du dépôt et
a un numero de ligne. Ces défauts sont **present dans le code d'origine** et
sont donc independants des artefacts ecartes.

## 1. Defauts bloquants

### 1.1 Controle d'equilibre du triage commente

`arbiochem-ejb/src/java/ferme/triageBatiment/TriageBatimentParquet.java:93-121`

Tout le corps de `createObject` est commente, y compris la verification que la
somme des quantites filles egale les quantites disponibles male et femelle.
`createObject` retombe sur `super.createObject(u, c)`.

Impact : aucune garantie qu'un lot ne soit pas range plus que sa disponibilite.

### 1.2 Nom de package errone dans la mere

`TriageBatimentParquet.java:71`

```java
this.setNomClasseFille("ferme.tirageBatiment.TriageBatimentParquetDetail");
```

Le package reel est `ferme.triageBatiment`. Meme erreur dans
`TriageBatimentParquetDetail.java:74` et `:84`.

Impact : `Class.forName("ferme.tirageBatiment....")` leve
`ClassNotFoundException`. Le module ne fonctionne que parce que le JSP impose
le bon nom (`triagebatimentparquet-saisie.jsp:18`). Hors JSP — batch, evolution
de l'API — le module est inutilisable.

### 1.3 Capacite et effectif non alimentes

`arbiochem-war/web/pages/ferme/configuration/batiment-saisie.jsp:40-44`

```jsp
affichage.Champ.setVisible(pi.getFormufle().getChampFille("capacite"), false);
affichage.Champ.setVisible(pi.getFormufle().getChampFille("effectif"), false);
pi.getFormufle().getChampMulitple("idLot").setVisible(false);
```

`BatimentDetail.effectif` (ligne 18) est donc toujours a 0 et `idLot` toujours
nul. Le controle de capacite de `Batiment.java:143-145` ne peut pas s'exercer.

Impact : aucune gestion de surcharge d'un batiment ou d'un parquet dans tout le
projet.

### 1.4 Aucune sortie du lot

- `lot-fiche.jsp:93` — bouton « Cloturer » commente.
- `lot-saisie.jsp:34` — `dateCloture` non saisissable.
- Aucune occurrence de `sortie` dans `ferme/`.
- Aucune facture ni livraison generee depuis le lot.

Impact : les animaux sortent du systeme sans trace commerciale.

## 2. Defauts de robustesse

### 2.1 `controlerUpdate` jamais surcharge dans le domaine ferme

`ClassMAPTable.controlerUpdate` est un no-op. Seul `controler` (insertion) est
surcharge dans `ReceptionPoussinAeroport`.

Consequence : une reception modifiee apres coup peut avoir
`somme(qte filles) != qteRecus`. Le controle de `checkQteFille()` ne rejoue
que sur l'insertion.

### 2.2 Champ `etat` absent des beans

`ReceptionPoussinAeroport` declare 4 champs (lignes 12-15) et
`TriageBatimentParquet` 5 (lignes 13-17). Ni l'un ni l'autre ne declare
`etat`, qui est pourtant herite de `ClassEtat` (ligne 15 / 12) et utilise par
les pages.

Impact : si `listeColonneTable` ne porte pas `ETAT` pour la table, le champ
disparait du formulaire. La colonne est affichee dans
`receptionaeroport-liste.jsp:11` (`etatlib`), donc la table doit le porter —
mais le bean ne peut pas le serialiser de facon explicite.

### 2.3 Casse des noms de tables heterogene

- Minuscules : `receptionPoussinAeroport`, `receptionPoussinAeroportDetail`,
  `distributionAliment`, `distributionAlimentDetail`, `TransfertPouletDetail`,
  `souche`, `origineLot`.
- Majuscules : tout le reste du domaine.

Impact : toute requite doit reprendre exactement la valeur du `setNomTable`.
Une requete ecrite « a la main » avec la mauvaise casse echoue sans diagnostic.

### 2.4 Sequences nommees comme des fonctions

`preparePk("RPA", "GETSEQRECEPTIONPOUSSINAEROPORT")` — le second argument est
utilise par `Utilitaire.getMaxSeq`
(`decompiled/apj-core/utilitaire/Utilitaire.java:1963-1990`, appel Oracle
ligne 1971) comme nom de fonction dans `select <nom> from dual`.
Aucune sequence de ce nom ne peut exister sans provoquer `ORA-00904`.
La variante `getMaxSeqDirecte` (ligne 1940) utilise, elle, `.nextval`.

Les 96 classes metier du domaine utilisent ce schema sans exception.

### 2.5 Concatenation SQL sans echappement

`inc/*.jsp` — `setAWhere(" and idmere='" + request.getParameter("id") + "'")`

`inc/batiment-details.jsp`, `inc/receptionaeroport-details.jsp`,
`inc/triagebatimentparquet-det.jsp`, et les autres fragments.

Impact : injection SQL theorique. Peu exploitable en l'etat car `id` provient
d'un objet existant, mais le defaut est reel.

### 2.6 `but` non valide

`pages/module.jsp:71` inclut le parametre `but` sans liste blanche. Un `../`
permettrait de remonter dans l'arborescence JSP.

## 3. Defauts de conception

### 3.1 Deux implementations de la mise en parquet

| Module | Classe fille | Particularite |
| --- | --- | --- |
| `triageBatiment` | `TriageBatimentParquetDetail` | import ; utilise `v_qte_dispo_lot_sexe_qualite` |
| `couvoir` | `TriageQualitePoussinDetail` | production locale ; porte `ideclosoir`, `idincubateur` |

Schema identique (`idbatiment`, `idparquet`, `idqualite`, `qte`), aucune table
commune, aucun code partage, aucun chainage entre les deux.

Impact : deux sources de verite pour « ou sont mes animaux ».

### 3.2 Le programme zootechnique n'est pas opposable

`ProgrammeZootechniqueDetails` porte 27 champs dont `poids`, `mortalite`,
`tauxeclosion`, `consoalimentfemelle`. `age` est une chaine, `poids` un double.

Aucun champ « poids reel » dans `SuiviJournalierDetail`. Aucun code ne compare
l'attendu au reel.

Impact : le module est declaratif, non contraignant.

### 3.3 Aucun chainage apres le triage

Sur les 34 modules du domaine, seuls deux bonds automatiques existent :

| Bond | Emplacement |
| --- | --- |
| Reception validee → Triage | `receptionaeroport-fiche.jsp:75` |
| Lot → onglet Repartitions | `lot-fiche.jsp:108` |

Les sept modules d'elevage sont des triplets independants. Le seul point de
convergence est le lien de colonne `idLot` vers `lot-fiche.jsp`.

### 3.4 `ConfigPoids` non branche

`ferme/utils/ConfigPoids.java` lit la vue `CONFIGPOIDS_LIB` et expose
`genererPlagePoids(min, max, pas)`. Aucun module — `pesee` compris — ne
l'appelle. Les fourchettes de poids prevues ne sont appliquees nulle part.

### 3.5 Page orpheline

`production/fumigationsimple-saisie.jsp` existe en plus des trois pages du
module `Fumigation`, qui n'a pas de classe fille et n'utilise donc pas
`PageInsertMultiple`.

Impact : page non atteignable depuis un flux coherent.

### 3.6 Heritage atypique

`couvoir/ImportOAC extends ReceptionOACLib`, table `IMPORTOAC`. Une classe
d'import qui herite d'une **vue** plutot que d'une mere. Ni `construirePK`
propre, ni lien de fille.

Cas unique dans tout le domaine.

## 4. Faiblesses du framework APJ lui-memes

### 4.1 Metadonnees en base, silencieusement

`ListeColonneTable.java:289` ne retient que l'intersection entre les colonnes
de la table de metadonnees et les `Field` Java declares.

Impact : un champ absent du bean **ou** de la base disparait du formulaire,
sans erreur ni trace. C'est le mecanisme qui rend `effectif` invisible.

### 4.2 `setAWhere` en concatenation

Voir 2.5.

### 4.3 Champs dupliques avec suffixe `_0`

`PageInsertMultiple` duplique les champs filles en `nombreLigne` copies, avec
les suffixes `_0` a `_9`. Les libelles se posent sur **`_0`** uniquement.

`getChampMulitple(nom)` — faute d'orthographe dans le framework — regroupe les
dix lignes d'une colonne.

Impact : une evolution du framework doit maintenir ces deux conventions.

## 5. Ce qui est correct et mérite d'etre conserve

Pour equilibrer le bilan, cinq elements du code d'origine sont de bonne facture
et servent de reference :

| Element | Emplacement | Qualite |
| --- | --- | --- |
| `genererLivraison(u, c)` | `As_BonDeCommande.java:466` | connexion externe, commit par l'appelant, rollback propre |
| `checkQteFille()` | `ReceptionPoussinAeroport.java:133` | controle metier reel et obligatoire |
| controle de capacite | `Batiment.java:143-145` | logique correcte, bien qu'inactive cote interface |
| `v_qte_dispo_lot_sexe_qualite` | vue SQL via `TriageLotSexeQualite` | le seul calcul serveur du domaine |
| chainage conditionne par etat | `receptionaeroport-fiche.jsp:74-75` | le seul chainage bien concu du projet |

Le dernier est le modele a reproduire : le passage au triage n'est propose que
si la reception est validee, et il ne transmet que `idLot` — l'objet suivant
recalcule son etat au lieu de faire confiance au precedent.