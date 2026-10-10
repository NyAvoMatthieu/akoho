# `triageBatiment` — le rangement effectif

**C'est l'equivalent le plus proche, et le seul existant, de la « mise en
compartiment ».** Le projet range les animaux dans le couple
`idbatiment` + `idparquet`, avec ventilation par sexe et par qualite.

`arbiochem-ejb/src/java/ferme/triageBatiment/`

## 1. Les 5 classes

| Classe | Heritage | Table | Cle |
| --- | --- | --- | --- |
| `TriageBatimentParquet` | `ClassMere` (l.12) | `TRIAGEBATIMENTPARQUET` (l.70) | `TB` / `getseq_triagebatimentparquet` (l.77) |
| `TriageBatimentParquetDetail` | `ClassFille` (l.6) | `TRIAGEBATIMENTPARQUETDETAIL` (l.83) | `TBD` / `getseq_triagebatparquetdetail` (l.90) |
| `TriageBatimentParquetLib` | mere | `TRIAGEBATIMENTPARQUET_LIB` (l.6) | — |
| `TriageBatimentParquetDetailLib` | fille | `TRIAGEBATPARQUETDETAIL_LIB` (l.6) | — |
| `TriageLotSexeQualite` | `extends TriageBatimentParquetDetail` (l.9) | **`v_qte_dispo_lot_sexe_qualite`** (l.12) | — |
| `TriageLotSexeQualiteLib` | `ClassMAPTable` | **`QTE_DISPO_LOT_SEXE_QUALITELIB`** (l.10) | — |

Les deux dernieres ne sont pas des tables mais des **vues SQL** qui recalculent
les disponibilites. Leur code est dans la base, pas dans le depot.

## 2. Champs

### Mere (lignes 13-17)

| Champ | Type | Role |
| --- | --- | --- |
| `id` | `String` | cle `TB` |
| `daty` | `Date` | date du triage |
| `idlot` | `String` | le lot — liaison vers le domaine |
| `dispomale` | `int` | **quantite male disponible**, pre-remplie en lecture seule |
| `dispofemelle` | `int` | idem femelle |
| `etat` | `int` | herite de `ClassEtat` |

### Fille (lignes 7-13) — la ligne de rangement

| Champ | Type | Role |
| --- | --- | --- |
| `id`, `idmere` | `String` | cle et liaison |
| `idbatiment` | `String` | `BATIMENT` — le batiment |
| `idparquet` | `String` | `PARQUET` — **le compartiment physique** |
| `idsexe` | `String` | `SEXE`, `ConstanteFerme.IDSEXEMALE` / `IDSEXEFEMELLE` |
| `idqualite` | `String` | `QUALITEPOUSSIN` |
| `qte` | `int` | **la quantite rangee** |

Une ligne = un parquet × un sexe × une qualite. Le rangement dans le projet
est donc un triplet, pas un couple.

## 3. Le mecanisme des disponibilites

C'est le point le plus interessant du module. `TriageBatimentParquet` ne
calcule rien : il lit la vue `v_qte_dispo_lot_sexe_qualite`.

`getDisponnible` (lignes 125-148) — quantite disponible pour un lot et un sexe :

```java
TriageLotSexeQualite t = new TriageLotSexeQualite();
t.setIdLot(idLot);
t.setIdsexe(idSexe);
t.setIdqualite(ConstanteFerme.qualiteConforme);   // QP000001
TriageLotSexeQualite[] r = (TriageLotSexeQualite[]) CGenUtil.rechercher(t, null, null, c, "");
return (r.length > 0) ? r[0].getQte() : 0;
```

`getDisponnibleLib` (lignes 150-173) — meme chose via la vue
`QTE_DISPO_LOT_SEXE_QUALITELIB`, en acceptant une qualite quelconque.

Les deux ouvrent leur propre connexion si `c` est `null`, et la ferment dans le
`finally` (lignes 143-147, 168-172).

La vue est donc le seul point du systeme ou « ce qui reste » est calcule. Elle
est alimentee en amont par les receptions d'aeroport. Une fois le triage valide
pour une quantite, la quantite ne doit plus apparaitre comme disponible — ce
qui suppose que la vue tienne compte du triage, et non seulement de la
reception.

## 4. Le controle de coherence est COMMENTE

`TriageBatimentParquet.createObject` (lignes 92-123) est surcharge, mais tout
son corps est commente. Les lignes 93-121 contenaient precisement la
verification d'equilibre :

```java
//        double sommeMale = 0;
//        double sommeFemelle = 0;
//        for (int i = 0; i < triageBatimentParquetDetails.length; i++) {
//            String idsexe = triageBatimentParquetDetails[i].getIdsexe();
//            double qte = triageBatimentParquetDetails[i].getQte();
//            if (ConstanteFerme.IDSEXEMALE.equals(idsexe))      sommeMale += qte;
//            else if (ConstanteFerme.IDSEXEFEMELLE.equals(idsexe)) sommeFemelle += qte;
//            else throw new Exception("Sexe non reconnu pour la ligne de detail: " + idsexe);
//        }
//        if (sommeMale != quantiteMale)
//            throw new Exception("La quantite totale des males triees (" + sommeMale
//                + ") ne correspond pas a la quantite disponible male (" + quantiteMale + ")");
//        if (sommeFemelle != quantiteFemelle)
//            throw new Exception("La quantite totale des femelles triees (...)");

    return super.createObject(u, c);
```

**Consequence : rien ne garantit que la somme des `qte` du detail egale les
quantites disponibles.** On peut ranger plus que disponible, ou moins, sans
erreur. Le module a perdu sa principale garantie metier.

Il n'y a pas non plus de controle de capacite du parquet, ni de verification que
le parquet appartient au batiment choisi — la coherence est uniquement
imposee par l'interface, via la liste deroulante enchanee.

## 5. Defaut de nom de classe fille

`TriageBatimentParquet.java:71` :

```java
this.setNomClasseFille("ferme.tirageBatiment.TriageBatimentParquetDetail");
```

Le package reel est `ferme.triageBatiment` — **`tirage` au lieu de `triage`**.
Meme erreur dans `TriageBatimentParquetDetail.java:73` (`getNomClasseMere`)
et `:84` (constructeur).

Consequence : tout `Class.forName("ferme.tirageBatiment....")` leve
`ClassNotFoundException`. Le module fonctionne uniquement parce que le JSP
contourne le chemin defectueux :

`triagebatimentparquet-saisie.jsp:18`

```java
String classeFille = "ferme.triageBatiment.TriageBatimentParquetDetail";
```

C'est le JSP qui impose le bon nom au framework. Toute utilisation hors JSP du
module — un batch, un appel Java, une evolution — echouerait.

## 6. La page de saisie

`triagebatimentparquet-saisie.jsp` — `PageInsertMultiple`, 10 lignes filles.

### Pre-remplissage en lecture seule (lignes 44-53)

```java
if (idLot != null && !idLot.isEmpty()) {
    pi.getFormu().getChamp("idlot").setDefaut(idLot);
    pi.getFormu().getChamp("idlot").setAutre("readonly");
    double femelleDispo = mere.getDisponnibleLib(idLot, ConstanteFerme.IDSEXEFEMELLE, ConstanteFerme.qualiteConforme, null);
    double maleDispo    = mere.getDisponnibleLib(idLot, ConstanteFerme.IDSEXEMALE,    ConstanteFerme.qualiteConforme, null);
    pi.getFormu().getChamp("dispomale").setDefaut(Double.toString(maleDispo));
    pi.getFormu().getChamp("dispofemelle").setDefaut(Double.toString(femelleDispo));
    pi.getFormu().getChamp("dispomale").setAutre("readonly");
    pi.getFormu().getChamp("dispofemelle").setAutre("readonly");
}
```

Les disponibilites ne sont donc **pas saisissables** : elles viennent de la vue.
C'est le seul module du domaine ou un calcul serveur alimente un champ du
formulaire.

### Listes deroulantes enchainees (lignes 55-63)

```java
Liste[] liste = new Liste[4];
liste[0] = new Liste("idsexe", sexe, "val", "id");
liste[2] = new Liste("idparquet", new ParquetBatiment(), "val", "id");
liste[1] = new Liste("idbatiment", new Batiment(), "nomBatiment", "id");
liste[1].setDeroulanteDependante(liste[2], "idbatiment", "onchange");
liste[3] = new Liste("idqualite", new QualitePoussin(), "val", "id");
```

`ParquetBatiment` lit `PARQUET_BATIMENT_LIB`, ce qui restreint les parquets a
ceux du batiment choisi. La coherence batiment/parquet est donc portee par
l'interface, jamais verifiee cote serveur.

### Libelles de la grille (lignes 65-69)

```java
pi.getFormufle().getChamp("idbatiment_0").setLibelle("Batiment");
pi.getFormufle().getChamp("idparquet_0").setLibelle("Parquet");
pi.getFormufle().getChamp("idsexe_0").setLibelle("Sexe");
pi.getFormufle().getChamp("idqualite_0").setLibelle("Qualite");
pi.getFormufle().getChamp("qte_0").setLibelle("Quantite");
Champ.setVisible(pi.getFormufle().getChampMulitple("idmere").getListeChamp(), false);
```

Ordre des colonnes (ligne 75) :

```java
String[] colOrdre = {"idbatiment", "idparquet", "idsexe", "idqualite", "qte"};
```

## 7. Le panneau de consultation

`inc/triagebatimentparquet-det.jsp` est le seul affichage de repartition du
projet, et il est utilise dans deux contextes (lignes 15-20) :

```java
if (request.getParameter("id") != null && request.getParameter("isLot") == null) {
    pr.setAWhere(" and idmere='" + request.getParameter("id") + "'");
} else if (request.getParameter("id") != null && request.getParameter("isLot") != null) {
    pr.setAWhere(" and idlot='" + request.getParameter("id") + "'");
}
```

Vue lue : `TRIAGEBATPARQUETDETAIL_LIB`. Colonnes (ligne 10) et libelles
(ligne 25) :

```
idBatimentLib  idParquetLib  idQualiteLib  idSexeLib  qte
Batiment       Parquet       Qualite       Sexe        Quantite
```

Le meme onglet est reachable depuis le lot — `lot-fiche.jsp:57` le declare dans
les onglets sous le libelle « Repartitions » (ligne 108). C'est donc la vue de
synthese d'un lot : tous ses parquets, tous ses parquets par sexe et qualite.

## 8. Chaine de navigation

```
Reception d'aeroport validee
   receptionaeroport-fiche.jsp:75
        &but=ferme/triagebatiment/triagebatimentparquet-saisie.jsp&idLot=<idLot>
             |
             v
   TriageBatimentParquet  (idlot, dispomale, dispofemelle)
        10 lignes : (idbatiment, idparquet, idsexe, idqualite, qte)
             |
             v
   validation  ->  plus de chainage automatique
```

**Apres le triage, le flux s'arrete.** Aucun bouton ne mene au suivi journalier,
a la vaccination ou au transfert. Ces modules sont des triplets independants,
atteignables par le menu ou par un lien de colonne `idLot` vers
`lot-fiche.jsp`.