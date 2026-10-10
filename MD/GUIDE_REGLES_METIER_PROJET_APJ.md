# Guide APJ : règles métier d’un projet spécifique

## Répartition recommandée

```text
Classe métier        : invariants de l’objet et calculs locaux
UserEJB / service     : transaction, orchestration, droits, plusieurs objets
ClassMere/ClassFille  : cohérence maître/détails
ClassEtat             : transitions et validations
JSP                   : saisie, affichage et navigation uniquement
```

## Dans la classe métier

Ajouter les règles qui doivent être vraies quel que soit l’écran :

- `controler(Connection)` : insertion et contrôles généraux ;
- `controlerUpdate(Connection)` : règles propres à la modification ;
- `controlerDelete(Connection)` : règles propres à la suppression ;
- `construirePK(Connection)` : génération de l’identifiant ;
- `createObject`, `updateObject`, `validerObject` : effets métier spécifiques, seulement si l’orchestration standard ne suffit pas.

Toujours appeler `super` quand la méthode parente porte déjà un contrôle.

```java
@Override
public void controler(Connection c) throws Exception {
    super.controler(c);
    if (quantite <= 0) {
        throw new Exception("La quantité doit être positive");
    }
}
```

## Dans le service ou `UserEJB`

Mettre ici les règles qui :

- impliquent plusieurs objets ou tables ;
- nécessitent une transaction unique ;
- dépendent de l’utilisateur, du rôle, de la direction ou de la configuration ;
- déclenchent stock, caisse, notification, historique ou pièces jointes.

Passer une `Connection` existante lorsque plusieurs écritures doivent réussir ou échouer ensemble. Gérer `commit`, `rollback` et fermeture au même niveau que l’ouverture.

## États et maître/détail

Pour un objet `ClassEtat`, ne pas modifier directement `etat` pour contourner le workflow : utiliser `validerObject`, `viserObject`, `retournerObject`, `recuObject`, `cloturerObject` ou la méthode métier prévue. Pour un `ClassMere`, propager explicitement les contrôles et changements aux `ClassFille`.

## À éviter

- règle métier uniquement dans une JSP ;
- SQL direct qui contourne historique et autorisations ;
- test dispersé du rôle dans toutes les pages ;
- appel à une opération externe avant la validation et la transaction ;
- modification d’un objet validé sans règle d’annulation claire.

## Méthode de conception

1. Identifier l’objet, la table, l’état et les dépendances.
2. Écrire l’invariant dans `controler*` si elle concerne un seul objet.
3. Écrire l’orchestration dans `UserEJB`/service si elle concerne plusieurs objets.
4. Ajouter le droit correspondant.
5. Tester succès, refus métier, refus d’autorisation et rollback.
