# Inventaire des pages JSP du domaine ferme

`arbiochem-war/web/pages/ferme/` — **115 JSP**, dont **13 artefacts** ecartees
(crees le 2026-10-05). Il reste donc **102 pages originales**.

## Regle de tri

| Prefixe | Role |
| --- | --- |
| `X-liste.jsp` | `PageRecherche` : SELECT + totaux + pagination |
| `X-saisie.jsp` | `PageInsert` (simple) ou `PageInsertMultiple` (mere/filles) |
| `X-fiche.jsp` | `PageConsulte` + boutons Valider / Modifier / Supprimer |
| `inc/X-det*.jsp` | fragment d'onglet, inclus par la fiche |

Convention constante sur les 34 modules : liste → saisie → fiche → onglet.
Trois suffixes sont mal orthographies dans le code original
(`transfetpoulet`, `suivijournlier`, `triagequlitepoussin`) ; ils fonctionnent
car le `<jsp:include>` utilise exactement la meme chaine.

## 1. Cœur du flux — 11 pages

| Repertoire | Pages | Module |
| --- | --- | --- |
| `lot/` | `lot-liste`, `lot-saisie`, `lot-fiche` | `Lot` |
| `receptionaeroport/` | `receptionaeroport-liste`, `-saisie`, `-fiche` + `inc/receptionaeroport-details` | comptage d'arrivee |
| `triagebatiment/` | `triagebatimentparquet-liste`, `-saisie`, `-fiche` + `inc/triagebatimentparquet-det` | **rangement effectif** |

`lot/` est le seul repertoire du domaine sans page `inc/`.

## 2. Suivi et actes d'elevage — 25 pages

| Repertoire | Racine | `inc/` | Module |
| --- | --- | --- | --- |
| `suiviJournalier/` | 3 | `suivijournlier-det.jsp` | suivi d'effectif |
| `vaccination/` | 3 | `vaccinationpoussin-details.jsp` | vaccination |
| `transfertpoulet/` | 3 | `transfetpoulet-det.jsp` | deplacement de parquet |
| `pesee/` | 3 | `peseepoussin-det.jsp` | pesee |
| `aliment/` | 3 | `distributionaliment-details.jsp` | distribution |
| `batiment/` | 3 | `batimentvidesanitaire-details.jsp` | desinfection |
| `programme/` | 3 | `programmezoodet.jsp` | referentiel theorique |

## 3. Couvoir — 16 pages

| Repertoire | Racine | `inc/` |
| --- | --- | --- |
| `couvoir/` | 12 (`eclosion`, `miseneincubateur`, `suivichambrefroide`, `triagequalitepoussin`) | 4 |

## 4. Production — 22 pages

| Repertoire | Racine | `inc/` |
| --- | --- | --- |
| `production/` | 19 | 3 |

Six modules : `fumigation`, `importoac`, `mirage`, `qualitetriageoeuf`,
`receptionoac`, `triageoeuf`.

Anomalie : `fumigationsimple-saisie.jsp` existe **en plus** des trois pages du
module, sans `PageInsert` ni `PageInsertMultiple` correspondant dans
`Fumigation.java` (qui n'a pas de fille). Page orpheline.

## 5. Referentiels `configuration/` — 25 pages

| Module | Pages |
| --- | --- |
| `Batiment` | 3 + `inc/batiment-details.jsp` |
| `Parquet` | 3 |
| `Eclosoir` | 3 |
| `Incubateur` | 3 |
| `QualitePoussin` | 3 |
| `Souche` | 3 |
| `OrigineLot` | 3 |
| `Vehicule` | 3 |

`Batiment` est le seul referentiel avec un onglet, parce que c'est le seul qui
ait des filles (`BatimentDetail`).

## 6. Artefacts ecartees — 13 pages

Ne pas documenter comme fonctionnel existant :

```
acheminement/controle-poulet-liste.jsp
acheminement/controle-poulet-saisie.jsp
acheminement/controle-poulet-fiche.jsp
acheminement/repartition-liste.jsp
acheminement/repartition-saisie.jsp
acheminement/repartition-fiche.jsp
acheminement/inc/repartition-details.jsp
poulet/poulet-liste.jsp
poulet/poulet-saisie.jsp
poulet/poulet-fiche.jsp
configuration/compartiment/compartiment-liste.jsp
configuration/compartiment/compartiment-saisie.jsp
configuration/compartiment/compartiment-fiche.jsp
```

## 7. Points d'entree du domaine

Aucun servlet ne sert ces pages. Le seul point d'entree garanti est
`ferme/lot/lot-liste.jsp` : c'est le seul module sans dependance a une
nomenclature pre-remplie.

Le menu est **dynamique**, stocke en base (`MENUDYNAMIQUE`, `USERMENU`) et lu
par `pages/elements/menu/module.jsp:30`. `HREF` est directement navigable.

Aucun `.sql` du depot ne contient d'insertion dans ces tables. Un module n'est
donc atteignable par menu que si un administrateur a cree ses lignes a la main.
Le reste n'est accessible que par URL directe ou par lien de colonne
`idLot` vers `lot-fiche.jsp`.

## 8. Les trois pages de dispatch

Hors `ferme/`, mais dans le chemin de toute ecriture :

| Page | Role |
| --- | --- |
| `pages/apresMultiple.jsp` | objet simple + filles : `getObjectAvecValeur()` puis `u.createObjectMultiple()` |
| `pages/apresTarif.jsp` | objet simple : `Class.forName(classe)` puis `u.createObject()` |
| `pages/module.jsp` | point d'entree : `<jsp:include>` de `but`, sans liste blanche |

Details du pattern dans `MD/10-ARCHITECTURE-APJ.md`.