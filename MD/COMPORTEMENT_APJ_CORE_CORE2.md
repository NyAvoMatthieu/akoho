# Comportement observable de `apj-core` et `apj-core2`

## Résumé

```text
apj-core  = noyau objet, persistance, historique, affichage et états
apj-core2 = extensions métier, droits, menus, services et web
```

`apj-core2` n’est pas autonome dans le décompilage observé : ses classes importent `bean.ClassMAPTable`, `bean.ClassEtat` et `bean.CGenUtil`, qui appartiennent au socle APJ. Il faut donc charger les deux bibliothèques dans l’ordre/configuration prévu par le build.

## `apj-core`

### `ClassMAPTable`

Une classe métier fournit généralement :

- `setNomTable(...)` ;
- `getTuppleID()` et `getAttributIDName()` ;
- `construirePK(Connection)` ;
- les getters/setters correspondant aux colonnes.

Le noyau utilise la réflexion pour découvrir les champs/méthodes, construire les opérations SQL, lire/rechercher par page, insérer, modifier, supprimer et écrire l’historique selon la méthode appelée (`insertToTableWithHisto`, `updateToTableWithHisto`, etc.). Les détails SQL et transactionnels restent dépendants de la version du JAR.

### `ClassEtat`

Il ajoute un état et des transitions de workflow. La validation peut vérifier : rôle, personne autorisée, ordre des rôles précédents, état déjà atteint, puis persister l’état et l’historique.

### `ClassMere` / `ClassFille`

La création et la validation du maître peuvent propager l’opération aux détails. Un détail peut refuser la modification/suppression lorsque le maître est déjà validé.

## `apj-core2`

Les éléments observables ajoutés sont notamment :

- `utilisateur.ActionRole`, `Role`, `Restriction`, `UtilisateurRole` ;
- `menu.MenuDynamique` et `UserMenu` ;
- `modules.GestionRole` ;
- services, notifications, import et servlets web.

`MenuDynamique` filtre l’arbre visible selon utilisateur, rôle, service, direction et interdictions. Ce filtrage ne remplace pas `ActionRole` ni les contrôles métier.

## Flux complet observé dans le projet

```text
JSP
 -> UserEJB
 -> contrôle ActionRole / état
 -> controler* de l’objet
 -> PK si création
 -> ClassMAPTable / ClassMere
 -> SQL Oracle
 -> historique et commit
```

Les classes projet `CreateObject`, `UpdateObject`, `ValiderObject` rendent ce flux explicite : création = initialisation éventuelle de `etat`/`iduser`, contrôle, PK, insertion avec historique ; mise à jour = alimentation de `iduser` puis mise à jour ; validation = droit `valider`, contrôle d’état puis changement d’état.

## Limites à garder

- Le code des JAR décompilés n’est pas la source originale.
- Le dispatcher JSP `but` et certains détails de transaction ne sont pas entièrement visibles.
- Ne pas déduire qu’une méthode publique est toujours appelée automatiquement : vérifier le chemin `UserEJB`/JSP utilisé.
- Pour une migration ou une nouvelle version, comparer les signatures et exécuter des tests CRUD, historique, droits, états et maître/détail.
