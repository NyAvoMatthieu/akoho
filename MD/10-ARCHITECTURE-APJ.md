# Architecture APJ et mechanism transversal

Le framework APJ est une surcouche maison qui impose la forme de tous les beans
et de tous les JSP. Aucune application ne peut s'en-passer.

## 1. Hierarchie de persistance

```
ClassMAPTable              (abstract)  decompiled/apj-core/bean/ClassMAPTable.java
  +-- TypeObjet                        nomenclatures : SEXE, QUALITEPOUSSIN, PARQUET...
  +-- ClassUser
        +-- ClassEtat                  + champ int etat
              +-- ClassMere            + createObjectMultiple() : mere + filles
              +-- ClassFille           + liaison vers la mere
```

### `ClassMAPTable` — la racine

| Membre | Ligne | Role |
| --- | --- | --- |
| `setNomTable(String)` | — | table SQL. Convention : nom de la classe en majuscules. |
| `construirePK(Connection)` | 701 | surcharge obligatoire dans chaque classe metier |
| `preparePk(indice, nomSeq)` | 2680 | prefixe de cle + nom de la fonction compteur |
| `makePK(Connection)` | 695 | `indice + numero` |
| `getTuppleID()`, `getAttributIDName()` | — | nom de la colonne PK dans la table |
| `insertToTable` | 2265 | INSERT ; appelle `construirePK` si la PK est vide |
| `controler(Connection)` | 705 | **crochet metier, no-op par defaut** |

### Les crochets metier

Ce sont les seuls endroits ou une classe peut ajouter de la logique. Les
methodes sont des no-op dans la classe mere : sans surcharge, la validation
n'existe pas.

```
controler(Connection)          insertion          -> ClassMAPTable.controler
controlerUpdate(Connection)    modification      -> ClassMAPTable.controlerUpdate  (no-op)
controlerDelete(Connection)    suppression        -> ClassFille.controlerDelete
createObject(u, Connection)    ecriture          -> ClassMere.createObject (mere + filles)
validerObject(u, Connection)   transition d'etat -> ClassEtat.validerObject
```

`ClassEtat` (ligne 40) refuse toute modification au-dela de
`ConstanteEtat.getEtatValider()` (valeur **11**), et `validerObject` (ligne 146)
fait passer l'objet a 11.

### `ClassMere` — la transaction mere/filles

| Methode | Ligne |
| --- | --- |
| `getFille()` | 49 |
| `createObject(String u, Connection c)` | 78 |
| `createObjectFille` | 125 |
| `createObjectFilleMultiple` | 183 |
| `createObjectMultiple(String u, Connection c)` | 173 |

`createObjectMultiple` ecrit la mere et ses filles dans **la meme connexion** :
soit tout passe, soit rien. C'est le mecanisme utilise par tous les modules
`ferme`.

Configuration dans le constructeur de la classe mere :

```java
super.setNomTable("BATIMENT");
this.setNomClasseFille("ferme.configuration.BatimentDetail");
this.setLiaisonFille("idMere");        // colonne de la fille qui pointe vers la mere
```

## 2. Generation des cles

`construirePK` est surcharge dans les 96 classes metier du domaine, toujours
sous la meme forme :

```java
@Override
public void construirePK(Connection c) throws Exception {
    this.preparePk("RPA", "GETSEQRECEPTIONPOUSSINAEROPORT");
    this.setId(makePK(c));
}
```

Le second argument est le nom d'une **fonction** sans parametre, pas d'une
sequence : `Utilitaire.getMaxSeq` (`decompiled/apj-core/utilitaire/Utilitaire.java:1963-1990`, appel
Oracle ligne 1971) construit
`select <nom> from dual` et n'ajoute jamais `.nextval`. Une sequence portant ce
nom provoque `ORA-00904`.

A noter que la variante voisine `getMaxSeqDirecte` (ligne 1940) fait, elle,
`select <nom>.nextval` : le projet utilise la mauvaise des deux.

## 3. Le pattern JSP

Trois pages par entite, plus un fragment d'onglet.

| Page | Classe APJ | Sortie |
| --- | --- | --- |
| `X-liste.jsp` | `PageRecherche` | SELECT + totaux + pagination |
| `X-saisie.jsp` | `PageInsert` ou `PageInsertMultiple` | `<form>` |
| `X-fiche.jsp` | `PageConsulte` | consultation + 3 boutons |
| `inc/X-details.jsp` | `PageRecherche` | lignes filles |

### Point cle : la metadonnee vit en base

`ListeColonneTable` (`decompiled/apj-core/bean/ListeColonneTable.java:289`)
interroge une table de metadonnees et ne retient que l'**intersection** entre
les colonnes vues et les `Field` Java declares :

```java
"SELECT * FROM listeColonneTable where table_Name = upper('" + nomT + "') ..."
new Champ(dr.getString(3), dr.getString(4), dr.getInt(8), dr.getInt(9));
```

Consequence directe : un champ absent du bean Java **ou** de la base
disparait du formulaire sans diagnostic. `ETAT` est le piege classique : il
n'est declare ni dans `ReceptionPoussinAeroport` ni dans `TriageBatimentParquet`
mais herite de `ClassEtat` (ligne 15), et les pages lNevertheless
l'utilisent.

### Saisie simple — `PageInsert`

```java
PageInsert pi = new PageInsert(o, request, u);
pi.getFormu().getChamp("x").setVisible(false);
affichage.Liste[] listef = { new Liste("champ", new Bean(), "colLibelle", "colValeur") };
pi.getFormu().changerEnChamp(listef);
pi.getFormu().setOrdre(new String[]{"daty", "idLot"});
pi.preparerDataFormu();
pi.getFormu().makeHtmlInsertTabIndex();
```

Le `<form>` est ecrit a la main, pas genere par le framework :

```html
<form action="<%=pi.getLien()%>?but=apresTarif.jsp" method="post">
  <input name="acte"     type="hidden" value="insert">
  <input name="bute"     type="hidden" value=".../X-fiche.jsp">
  <input name="classe"   type="hidden" value="pkg.Classe">   <!-- nom Java complet -->
  <input name="nomtable" type="hidden" value="TABLE">
```

`classe` permet a `apresTarif.jsp:108` de faire `Class.forName(classe)`.

### Saisie mere/filles — `PageInsertMultiple`

```java
PageInsertMultiple pi = new PageInsertMultiple(mere, fille, request, 10, u);
pi.getFormu().getChamp("idlot").setLibelle("Lot");
pi.getFormufle().getChamp("idbatiment_0").setLibelle("Batiment");  // suffixe _0 !
affichage.Champ.setVisible(pi.getFormufle().getChampMulitple("idmere").getListeChamp(), false);
pi.getFormufle().setColOrdre(new String[]{"idbatiment","idparquet","idsexe","qte"});
```

Les champs filles sont dupliques `nombreLigne` fois avec les suffixes `_0` a
`_9`. Les libelles se posent donc sur **`_0`** uniquement. `getChampMulitple(nom)`
regroupe les dix lignes d'une meme colonne ; la faute d'orthographe est celle
du framework.

Listes deroulantes enchainees, le cas le plus courant du domaine ferme :

```java
liste[1] = new Liste("idbatiment", new Batiment(), "nomBatiment", "id");
liste[2] = new Liste("idparquet", new ParquetBatiment(), "val", "id");
liste[1].setDeroulanteDependante(liste[2], "idbatiment", "onchange");
```

Le second se recharge par requete quand le premier change.

Champs caches du formulaire fille :

```html
<input name="classefille"   type="hidden" value="pkg.ClasseDetail">
<input name="nombreLigne"   type="hidden" value="10">
<input name="colonneMere"   type="hidden" value="idmere">
```

### Les deux points d'attention

`setAWhere` (`inc/*.jsp`) concatene le parametre `id` sans echappement :
injection SQL theorique, peu exploitable en l'etat car `id` vient d'un objet
existant.

`but` est inclus tel quel dans `module.jsp:71`, sans liste blanche : un `../`
permettrait de remonter dans l'arborescence JSP.

## 4. La transaction

Aucun servlet n'est dans le chemin du domaine ferme. Tout passe par deux pages
de dispatch :

| Page | Modules qui postent vers elle |
| --- | --- |
| `pages/apresTarif.jsp` | objet simple : `Class.forName(classe)` → `u.createObject()` → redirection vers `bute` |
| `pages/apresMultiple.jsp` | mere + filles : `getObjectAvecValeur()` → `u.createObjectMultiple(cmere, colonneMere, cfille)` |

Les servlets `/ApresTarif` et `/ApresMultiple` de `arbiochem-war/src/java/servlet/`
sont des variantes JSON pour les actions de masse. Elles ne participent pas
au flux HTML.

## 5. Le menu

Le menu vit en base : `MENUDYNAMIQUE` (colonnes `ID, LIBELLE, ICONE, HREF,
RANG, NIVEAU, ID_PERE, DESCRIPTION`) et `USERMENU`, lus par
`MenuDynamique.getElementMenu` via `pages/elements/menu/module.jsp:30`.
`HREF` est directement navigable.

Aucun `.sql` du depot ne contient d'insertion dans ces tables : **un module
n'est atteignable par menu que si un administrateur a cree ses lignes**. Le
seul point d'entree garanti de tout le domaine ferme est
`ferme/lot/lot-liste.jsp`.