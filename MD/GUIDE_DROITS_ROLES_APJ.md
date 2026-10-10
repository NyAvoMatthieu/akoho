# Guide APJ : droits et rôles au-delà des menus

## Deux contrôles différents

Le menu contrôle principalement la visibilité d’une page. Il ne protège pas à lui seul une opération HTTP ni un appel Java.

```text
MenuDynamique / UserMenu : afficher ou masquer un lien
ActionRole / Restriction : autoriser une action sur un objet
controler*              : imposer la règle métier finale
```

## Autorisation d’une action

`utilisateur.ActionRole` compare une action (`create`, `update`, `delete`, `valider`, etc.) avec :

- la table de l’objet (`nomTableObjet`) ;
- le rang minimal du rôle (`roleminimum`) ;
- la direction autorisée (`direction`, plusieurs valeurs séparées par `;`, ou `%`) ;
- éventuellement le groupe de table (`groupeTable`).

`ActionRole.estAutorise(liste, utilisateur, action, objet)` autorise aussi les utilisateurs de rang DG et, selon le code observé, l’absence de règles chargées. Ce comportement doit être vérifié dans la configuration cible : il ne faut pas confondre « aucune règle chargée » et « accès refusé ».

Le service expose aussi `UserEJB.testRestriction(user, permission, table, connexion)` et `GestionRole.ajoutrestriction(...)`/`updateRestriction(...)`. Les restrictions sont stockées avec un rôle, une action, une table et éventuellement une direction.

## Où vérifier

- **JSP/servlet** : filtrer l’affichage et éviter les liens inutiles.
- **UserEJB** : vérifier l’action avant une opération centralisée.
- **Objet métier** : vérifier les invariants dans `controler`, `controlerUpdate`, `controlerDelete`.
- **Workflow** : `validerObject` vérifie l’action `valider` et les règles de `ClassEtat`.

Un appel direct à une méthode métier doit rester refusé même si l’utilisateur n’a pas vu le menu. Le menu est une aide d’ergonomie, pas une frontière de sécurité.

## Validation multi-rôle

`ClassEtat` peut utiliser `RoleValidation` : rôle attendu, personne autorisée, niveau et valeur d’état. Le code vérifie notamment le rôle de l’utilisateur, l’ordre des validations précédentes et l’état déjà atteint.

## Procédure d’ajout

1. Définir une action stable (`create`, `update`, `delete`, `valider`, ou nom métier).
2. L’associer à la table APJ réelle, pas seulement à l’URL.
3. Ajouter rôle, rang et direction si nécessaire.
4. Garder le contrôle dans `UserEJB`/`ActionRole` et dans l’objet métier.
5. Tester URL directe, appel POST direct, utilisateur sans rôle, mauvaise direction et utilisateur DG.
