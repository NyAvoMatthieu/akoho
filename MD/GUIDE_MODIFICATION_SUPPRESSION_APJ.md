# Guide APJ : modification et suppression

## Flux standard

Une JSP récupère l’utilisateur en session puis délègue à `UserEJB` :

```text
PageInsert / PageConsulte
  -> UserEJB.updateObject(o) ou deleteObject(o)
  -> hooks de l’objet
  -> SQL + historique
```

L’objet doit être chargé avec son identifiant (`getAttributIDName()` et `getTuppleID()`). Ne jamais supprimer directement par SQL depuis une JSP si l’opération doit respecter l’historique et les contrôles APJ.

## Modification

- `UserEJB.updateObject(o)` appelle le chemin uniforme de mise à jour.
- Pour un objet `ClassUser` ou `ClassEtat`, `iduser` est renseigné avec l’utilisateur courant.
- Les règles avant modification se placent dans `controlerUpdate(Connection)`.
- Pour un détail (`ClassFille`), le parent est recherché ; si son état est déjà validé, la modification est refusée.
- `updateObjectMultiple` traite le parent et les détails dans une même connexion avec commit/rollback.

```java
@Override
public void controlerUpdate(Connection c) throws Exception {
    super.controlerUpdate(c);
    if (getEtat() >= ConstanteEtat.getEtatValider()) {
        throw new Exception("Objet déjà validé");
    }
}
```

## Suppression

- `UserEJB.deleteObject(o)` est le point d’entrée normal.
- Les règles de suppression se placent dans `controlerDelete(Connection)`.
- Dans le modèle APJ, `controlerDelete` peut réutiliser `controlerUpdate` lorsque les mêmes verrouillages s’appliquent.
- Pour un maître/détail, utiliser les opérations `ClassMere`/`ClassFille` (`deleteFille`, `deleteMereFille`, ou `deleteObjectMultiple`) afin de traiter le lien correctement.
- Préférer une annulation, un changement d’état ou une désactivation lorsque l’objet est déjà validé, référencé ou historisé.

## Checklist

1. Charger l’objet par son identifiant.
2. Vérifier le droit `update` ou `delete`.
3. Laisser l’objet exécuter `controlerUpdate`/`controlerDelete`.
4. Utiliser `UserEJB`, avec une transaction pour plusieurs objets.
5. Vérifier l’état, les dépendances et l’historique.
6. Tester refus, rollback et cas maître/détail.
