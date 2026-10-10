# Bons de commande et bons de livraison avec `ProduitSimple`

Ce document explique le fonctionnement technique des bons de commande et des bons de livraison dans le framework APJ, en utilisant `ProduitSimple` comme exemple pédagogique.

L’objectif n’est pas de reproduire toute la logique métier existante, mais de comprendre comment APJ structure une opération composée d’un en-tête et de plusieurs lignes.

```text
bon de commande
  = en-tête + lignes de produits

bon de livraison
  = en-tête + lignes livrées

APJ
  = ClassMere + ClassFille + PageInsertMultiple + ClassEtat
```

## 1. Les classes réelles du projet

Le projet contient notamment :

```text
vente/BonDeCommande.java
vente/BonDeCommandeFille.java
vente/BonDeCommandeFIlleCpl.java
vente/As_BondeLivraisonClient.java
vente/As_BondeLivraisonClientFille.java
```

Les hiérarchies importantes sont :

```text
BonDeCommande extends ClassMere
BonDeCommandeFille extends ClassFille

As_BondeLivraisonClient extends ClassMere
As_BondeLivraisonClientFille extends ClassFille
```

Les pages correspondantes se trouvent notamment dans :

```text
arbiochem-war/web/pages/bondecommande/
arbiochem-war/web/pages/bondelivraison/
arbiochem-war/web/pages/bondelivraison-client/
```

Exemples :

```text
bondecommande/bondecommande-saisie.jsp
bondecommande/bondecommande-liste.jsp
bondelivraison/bondelivraison-saisie.jsp
bondelivraison/bondelivraison-liste.jsp
```

## 2. Le modèle maître/détail APJ

APJ représente un document composé avec deux objets :

```text
ClassMere
  └── ClassFille[]
```

Le parent contient les informations générales :

```text
id
client
date
état
magasin
remarque
```

La fille contient les lignes :

```text
id
identifiant du produit
quantité
prix
identifiant du parent
```

Pour `BonDeCommande`, le projet utilise conceptuellement :

```text
BonDeCommande
  └── BonDeCommandeFille[]
```

Pour un bon de livraison client :

```text
As_BondeLivraisonClient
  └── As_BondeLivraisonClientFille[]
```

## 3. Exemple de bon de commande avec `ProduitSimple`

Pour l’exemple, on peut imaginer les tables suivantes :

```sql
CREATE TABLE BON_COMMANDE_SIMPLE (
    ID VARCHAR2(20) PRIMARY KEY,
    DATY DATE,
    REMARQUE VARCHAR2(255),
    ETAT NUMBER,
    IDCLIENT VARCHAR2(20)
);

CREATE TABLE BON_COMMANDE_SIMPLE_LIGNE (
    ID VARCHAR2(20) PRIMARY KEY,
    IDBC VARCHAR2(20),
    IDPRODUIT VARCHAR2(20),
    QUANTITE NUMBER,
    PU NUMBER
);
```

La relation est :

```text
BON_COMMANDE_SIMPLE.ID
    = BON_COMMANDE_SIMPLE_LIGNE.IDBC
```

Dans la convention APJ, le nom du champ de liaison doit être cohérent dans les deux classes.

## 4. Classe parent `BonCommandeSimple`

```java
package produit;

import bean.ClassMere;
import java.sql.Connection;

public class BonCommandeSimple extends ClassMere {
    private String id;
    private java.sql.Date daty;
    private String remarque;
    private int etat;
    private String idClient;

    public BonCommandeSimple() throws Exception {
        setNomTable("BON_COMMANDE_SIMPLE");
        setLiaisonFille("idBc");
        setNomClasseFille("produit.BonCommandeSimpleLigne");
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        preparePk("BCS", "getSeqBonCommandeSimple");
        setId(makePK(c));
    }

    @Override
    public void controler(Connection c) throws Exception {
        super.controler(c);

        if (daty == null) {
            throw new Exception("La date est obligatoire");
        }

        if (getFille() == null || getFille().length == 0) {
            throw new Exception("Le bon de commande doit contenir une ligne");
        }
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public java.sql.Date getDaty() { return daty; }
    public void setDaty(java.sql.Date daty) { this.daty = daty; }

    public String getRemarque() { return remarque; }
    public void setRemarque(String remarque) { this.remarque = remarque; }

    public int getEtat() { return etat; }
    public void setEtat(int etat) { this.etat = etat; }

    public String getIdClient() { return idClient; }
    public void setIdClient(String idClient) { this.idClient = idClient; }
}
```

Les deux appels fondamentaux sont :

```java
setLiaisonFille("idBc");
setNomClasseFille("produit.BonCommandeSimpleLigne");
```

Ils indiquent à APJ :

- quelle propriété relie le parent à ses lignes ;
- quelle classe doit être instanciée pour charger les lignes.

## 5. Classe ligne `BonCommandeSimpleLigne`

```java
package produit;

import bean.ClassFille;
import java.sql.Connection;

public class BonCommandeSimpleLigne extends ClassFille {
    private String id;
    private String idBc;
    private String idProduit;
    private double quantite;
    private double pu;

    public BonCommandeSimpleLigne() throws Exception {
        setNomTable("BON_COMMANDE_SIMPLE_LIGNE");
        setNomClasseMere("produit.BonCommandeSimple");
        setLiaisonMere("idBc");
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        preparePk("BCSL", "getSeqBonCommandeSimpleLigne");
        setId(makePK(c));
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getIdBc() { return idBc; }
    public void setIdBc(String idBc) { this.idBc = idBc; }

    public String getIdProduit() { return idProduit; }
    public void setIdProduit(String idProduit) { this.idProduit = idProduit; }

    public double getQuantite() { return quantite; }
    public void setQuantite(double quantite) { this.quantite = quantite; }

    public double getPu() { return pu; }
    public void setPu(double pu) { this.pu = pu; }
}
```

La ligne référence `ProduitSimple` par son identifiant :

```java
private String idProduit;
```

La ligne ne contient pas nécessairement l’objet `ProduitSimple` complet. Elle contient généralement sa clé, puis APJ ou une classe de lecture peut charger les informations complémentaires.

## 6. Ce que fait `ClassMere` lors de l’insertion

L’implémentation décompilée de `ClassMere.createObject` réalise ce flux :

```text
1. insérer le parent
2. récupérer son identifiant
3. parcourir les filles
4. affecter l’identifiant parent dans chaque fille
5. insérer les filles
```

Le mécanisme est conceptuellement équivalent à :

```java
ClassMAPTable ret = super.createObject(user, connection);

for (ClassFille fille : getFille()) {
    fille.setValChamp(getLiaisonFille(), getTuppleID());
    fille.createObject(user, connection);
}
```

Ainsi, le code de la JSP n’a pas besoin de répéter manuellement l’identifiant du bon de commande pour chaque ligne.

## 7. Création d’un bon de commande en Java

```java
BonCommandeSimple bon = new BonCommandeSimple();
bon.setDaty(java.sql.Date.valueOf("2026-10-03"));
bon.setRemarque("Commande de produits simples");
bon.setEtat(1);

BonCommandeSimpleLigne ligne1 = new BonCommandeSimpleLigne();
ligne1.setIdProduit("PRS000001");
ligne1.setQuantite(10);
ligne1.setPu(2500);

BonCommandeSimpleLigne ligne2 = new BonCommandeSimpleLigne();
ligne2.setIdProduit("PRS000002");
ligne2.setQuantite(5);
ligne2.setPu(4000);

bon.ajouterFille(ligne1);
bon.ajouterFille(ligne2);
```

Puis, dans un service APJ disposant de l’utilisateur et d’une connexion :

```java
bon.createObject(referenceUtilisateur, connection);
```

Le résultat est :

```text
BON_COMMANDE_SIMPLE
  BCS000001 | 2026-10-03 | Commande de produits simples

BON_COMMANDE_SIMPLE_LIGNE
  BCSL000001 | BCS000001 | PRS000001 | 10 | 2500
  BCSL000002 | BCS000001 | PRS000002 | 5  | 4000
```

L’identifiant `BCS000001` est généré avant l’insertion des lignes.

## 8. Saisie web avec `PageInsertMultiple`

Les pages réelles de bon de commande utilisent :

```java
PageInsertMultiple pi = new PageInsertMultiple(
    mere,
    fille,
    request,
    nombreLigne,
    u
);
```

Dans le projet, la page [bondecommande-saisie.jsp](arbiochem-war/web/pages/bondecommande/bondecommande-saisie.jsp) instancie notamment :

```java
BonDeCommande mere = new BonDeCommande();
BonDeCommandeFIlleCpl fille = new BonDeCommandeFIlleCpl();

PageInsertMultiple pi = new PageInsertMultiple(
    mere,
    fille,
    request,
    nombreLigne,
    u
);
```

La différence avec `PageInsert` est importante :

```text
PageInsert
  -> formulaire pour un seul objet

PageInsertMultiple
  -> formulaire parent
  -> plusieurs lignes enfants
```

## 9. Ajouter une liste de `ProduitSimple` dans les lignes

Dans un formulaire maître/détail, la liste doit être appliquée au formulaire des filles, pas au formulaire du parent.

Exemple :

```java
Liste listeProduit = new Liste(
    "idProduit",
    new ProduitSimple(),
    "nom",
    "id"
);

pi.getFormufle().changerEnChamp(
    new affichage.Champ[] { listeProduit }
);
```

La structure est :

```text
pi.getFormu()
    -> champs du bon de commande

pi.getFormufle()
    -> champs des lignes
```

Pour le bon de commande réel, l’équivalent concerne le champ `produit` ou `idProduit` des lignes :

```java
affichage.Champ.setPageAppelComplete(
    pi.getFormufle().getChampFille("produit"),
    "produits.IngredientVente",
    "id",
    "AS_INGREDIENT_VENTE_LIB",
    "prixunitaire;libelle",
    "pu;designation"
);
```

Dans l’exemple `ProduitSimple`, le comportement minimal est :

```java
Champ[] choixProduit = new Champ[1];
choixProduit[0] = new Liste(
    "idProduit",
    new ProduitSimple(),
    "nom",
    "id"
);
pi.getFormufle().changerEnChamp(choixProduit);
```

## 10. Rendu du formulaire maître/détail

```jsp
<%
    pi.setLien((String) session.getValue("lien"));
    pi.preparerDataFormu();
%>

<form action="<%= pi.getLien() %>?but=apresTarif.jsp"
      method="post">

    <%= pi.getFormu().getHtmlInsert() %>
    <%= pi.getFormufle().getHtmlInsert() %>

    <input type="hidden" name="acte" value="insert">
    <input type="hidden" name="classe" value="produit.BonCommandeSimple">
    <input type="hidden" name="nomtable" value="BON_COMMANDE_SIMPLE">
    <input type="hidden" name="bute" value="produit/bon-commande-simple-fiche.jsp">
</form>
```

`PageInsertMultiple` génère des champs indexés pour les lignes :

```text
idProduit_0
quantite_0
pu_0

idProduit_1
quantite_1
pu_1
```

Le suffixe `_0`, `_1`, etc. représente la position de la ligne.

## 11. Requête HTTP d’un bon de commande

Une soumission peut ressembler à :

```text
POST /async-standard/pages/apresTarif.jsp

acte=insert
classe=produit.BonCommandeSimple
nomtable=BON_COMMANDE_SIMPLE
bute=produit/bon-commande-simple-fiche.jsp

daty=03/10/2026
remarque=Commande de produits simples

idProduit_0=PRS000001
quantite_0=10
pu_0=2500

idProduit_1=PRS000002
quantite_1=5
pu_1=4000
```

Le framework doit alors :

```text
paramètres HTTP
  -> objet parent
  -> tableau de lignes
  -> conversion des types
  -> validation du parent
  -> génération de la clé parent
  -> insertion du parent
  -> affectation de la clé parent aux lignes
  -> insertion des lignes
  -> historisation
```

## 12. Validation d’un bon de commande

`BonDeCommande` hérite de `ClassEtat` via `ClassMere`.

Les états représentent le cycle de vie :

```text
état initial
  -> création en cours
  -> validation
  -> clôture éventuelle
```

Le code APJ de validation maître/détail est conceptuellement :

```java
@Override
public Object validerObject(String user, Connection c) throws Exception {
    validerObjectFille(user, c);
    return super.validerObject(user, c);
}
```

La validation du parent entraîne donc la validation de ses lignes.

Dans l’implémentation réelle de `ClassMere`, les lignes sont parcourues avant l’appel à `super.validerObject`.

## 13. Création d’un bon de livraison

Un bon de livraison client possède une structure analogue :

```text
As_BondeLivraisonClient
  └── As_BondeLivraisonClientFille[]
```

L’en-tête contient notamment :

```text
id
idbc
idClient
magasin
daty
etat
```

La ligne contient notamment :

```text
id
numbl
produit
quantite
pu
idbc_fille
```

Le champ `idbc` du parent permet de conserver la référence du bon de commande d’origine.

## 14. Exemple de classe livraison simplifiée

```java
package produit;

import bean.ClassMere;
import java.sql.Connection;

public class BonLivraisonSimple extends ClassMere {
    private String id;
    private String idBc;
    private java.sql.Date daty;
    private String magasin;
    private int etat;

    public BonLivraisonSimple() throws Exception {
        setNomTable("BON_LIVRAISON_SIMPLE");
        setLiaisonFille("idBl");
        setNomClasseFille("produit.BonLivraisonSimpleLigne");
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        preparePk("BLS", "getSeqBonLivraisonSimple");
        setId(makePK(c));
    }

    @Override
    public void controler(Connection c) throws Exception {
        super.controler(c);

        if (idBc == null || idBc.trim().isEmpty()) {
            throw new Exception("Le bon de commande d'origine est obligatoire");
        }

        if (getFille() == null || getFille().length == 0) {
            throw new Exception("La livraison doit contenir une ligne");
        }
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getIdBc() { return idBc; }
    public void setIdBc(String idBc) { this.idBc = idBc; }

    public java.sql.Date getDaty() { return daty; }
    public void setDaty(java.sql.Date daty) { this.daty = daty; }

    public String getMagasin() { return magasin; }
    public void setMagasin(String magasin) { this.magasin = magasin; }

    public int getEtat() { return etat; }
    public void setEtat(int etat) { this.etat = etat; }
}
```

## 15. Ligne de livraison

```java
package produit;

import bean.ClassFille;
import java.sql.Connection;

public class BonLivraisonSimpleLigne extends ClassFille {
    private String id;
    private String idBl;
    private String idProduit;
    private double quantite;
    private double pu;
    private String idBcLigne;

    public BonLivraisonSimpleLigne() throws Exception {
        setNomTable("BON_LIVRAISON_SIMPLE_LIGNE");
        setNomClasseMere("produit.BonLivraisonSimple");
        setLiaisonMere("idBl");
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        preparePk("BLSL", "getSeqBonLivraisonSimpleLigne");
        setId(makePK(c));
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getIdBl() { return idBl; }
    public void setIdBl(String idBl) { this.idBl = idBl; }

    public String getIdProduit() { return idProduit; }
    public void setIdProduit(String idProduit) { this.idProduit = idProduit; }

    public double getQuantite() { return quantite; }
    public void setQuantite(double quantite) { this.quantite = quantite; }

    public double getPu() { return pu; }
    public void setPu(double pu) { this.pu = pu; }

    public String getIdBcLigne() { return idBcLigne; }
    public void setIdBcLigne(String idBcLigne) { this.idBcLigne = idBcLigne; }
}
```

La liaison entre une livraison et une commande est double :

```text
BonLivraisonSimple.idBc
  -> identifiant du bon de commande

BonLivraisonSimpleLigne.idBcLigne
  -> identifiant de la ligne commandée
```

Cette double liaison permet de connaître :

- la commande d’origine ;
- la ligne commandée ;
- la quantité commandée ;
- la quantité livrée ;
- le reste à livrer.

## 16. Calcul du reste à livrer

La ligne de commande peut conserver les quantités :

```java
private double quantite;
private double qteLivre;
```

Le reste est calculé ainsi :

```java
public double getResteLivre() {
    return quantite - qteLivre;
}
```

Exemple :

```text
quantité commandée = 10
quantité déjà livrée = 4
reste à livrer = 6
```

Code :

```java
BonCommandeSimpleLigne ligne = ...;

if (ligne.getResteLivre() <= 0) {
    throw new Exception("Cette ligne est déjà totalement livrée");
}
```

Lors de la création d’une livraison, la quantité livrée doit être contrôlée :

```java
if (quantiteLivree <= 0) {
    throw new Exception("La quantité livrée doit être positive");
}

if (quantiteLivree > resteA livrer) {
    throw new Exception("La quantité livrée dépasse le reste à livrer");
}
```

La variable doit naturellement être écrite sans espace dans le vrai code :

```java
if (quantiteLivree > resteALivrer) {
    throw new Exception("La quantité livrée dépasse le reste à livrer");
}
```

## 17. Générer une livraison depuis une commande

Le code pédagogique suivant transforme les lignes non totalement livrées :

```java
BonCommandeSimple commande = ...;
BonLivraisonSimple livraison = new BonLivraisonSimple();

livraison.setIdBc(commande.getId());
livraison.setDaty(java.sql.Date.valueOf("2026-10-03"));
livraison.setMagasin("MAG001");
livraison.setEtat(1);

for (ClassFille element : commande.getFille()) {
    BonCommandeSimpleLigne commandeLigne =
        (BonCommandeSimpleLigne) element;

    double reste = commandeLigne.getQuantite()
        - commandeLigne.getQteLivre();

    if (reste <= 0) {
        continue;
    }

    BonLivraisonSimpleLigne livraisonLigne =
        new BonLivraisonSimpleLigne();

    livraisonLigne.setIdProduit(commandeLigne.getIdProduit());
    livraisonLigne.setIdBcLigne(commandeLigne.getId());
    livraisonLigne.setQuantite(reste);
    livraisonLigne.setPu(commandeLigne.getPu());

    livraison.ajouterFille(livraisonLigne);
}
```

Puis :

```java
livraison.createObject(referenceUtilisateur, connection);
```

Le framework se charge de :

```text
insérer la livraison
  -> générer id livraison
  -> affecter idBl aux lignes
  -> insérer les lignes
  -> historiser
```

La mise à jour de `qteLivre` sur les lignes de commande reste une règle spécifique au projet. Elle ne doit pas être supposée automatiquement fournie par `ClassMere`.

## 18. Page de saisie de livraison

La page réelle de livraison utilise également un formulaire maître/détail :

```java
As_BondeLivraisonClient mere = new As_BondeLivraisonClient();
As_BondeLivraisonClientFille fille =
    new As_BondeLivraisonClientFille();

int nombreLigne = 10;

PageInsertMultiple pi = new PageInsertMultiple(
    mere,
    fille,
    request,
    nombreLigne,
    u
);
```

Le formulaire peut recevoir l’identifiant de la commande d’origine :

```text
?idbc=BC000001
```

La page peut alors charger les lignes de cette commande et préremplir les lignes de livraison.

Exemple pédagogique :

```jsp
<%
    String idBc = request.getParameter("idBc");

    BonCommandeSimple commande = new BonCommandeSimple();
    commande.setId(idBc);

    ClassFille[] lignes = commande.getFille(null, null, "");
%>
```

En pratique, l’implémentation réelle peut utiliser une classe complémentaire ou une vue SQL pour calculer les quantités restantes.

## 19. Formulaire de livraison avec `ProduitSimple`

```jsp
<%@page import="produit.BonLivraisonSimple"%>
<%@page import="produit.BonLivraisonSimpleLigne"%>
<%@page import="produit.ProduitSimple"%>
<%@page import="affichage.PageInsertMultiple"%>
<%@page import="affichage.Liste"%>
<%@page import="user.UserEJB"%>

<%
    UserEJB u = (user.UserEJB) session.getValue("u");

    BonLivraisonSimple mere = new BonLivraisonSimple();
    BonLivraisonSimpleLigne fille =
        new BonLivraisonSimpleLigne();

    PageInsertMultiple pi = new PageInsertMultiple(
        mere,
        fille,
        request,
        10,
        u
    );

    Champ[] produits = new Champ[1];
    produits[0] = new Liste(
        "idProduit",
        new ProduitSimple(),
        "nom",
        "id"
    );

    pi.getFormufle().changerEnChamp(produits);
    pi.preparerDataFormu();
%>
```

Le point important est l’utilisation de :

```java
pi.getFormufle()
```

La liste `ProduitSimple` appartient à la ligne de livraison, pas à l’en-tête.

## 20. Liste des bons de commande

Une page de liste d’en-têtes utilise `PageRecherche` :

```jsp
<%
    BonCommandeSimple critere = new BonCommandeSimple();
    critere.setNomTable("BON_COMMANDE_SIMPLE");

    String[] criteres = {"id", "daty", "idClient", "etat"};
    String[] intervalles = {};
    String[] entetes = {"id", "daty", "idClient", "etat"};

    PageRecherche pr = new PageRecherche(
        critere,
        request,
        criteres,
        intervalles,
        3,
        entetes,
        entetes.length
    );

    pr.setTitre("Bons de commande");
    pr.setUtilisateur((user.UserEJB) session.getValue("u"));
    pr.setLien((String) session.getValue("lien"));
    pr.setApres("produit/bon-commande-simple-liste.jsp");

    pr.creerObjetPage(entetes, null);

    String[] liens = {
        pr.getLien() + "?but=produit/bon-commande-simple-fiche.jsp"
    };

    pr.getTableau().setLien(liens);
    pr.getTableau().setColonneLien(new String[]{"id"});
%>
```

Les lignes du tableau pointent vers la fiche du bon de commande, qui peut ensuite proposer :

```text
Modifier
Valider
Créer une livraison
```

## 21. Lien « créer une livraison »

Dans la fiche d’un bon de commande :

```jsp
<a href="<%= lien %>?but=produit/bon-livraison-simple-saisie.jsp&idBc=<%= id %>">
    Créer une livraison
</a>
```

Le paramètre est transmis à la page de livraison :

```text
idBc=BCS000001
```

La page de livraison peut ensuite :

1. charger le bon de commande ;
2. charger ses lignes ;
3. calculer les restes ;
4. préremplir les produits ;
5. laisser l’utilisateur saisir les quantités livrées ;
6. enregistrer le bon de livraison.

## 22. États et validation

Les bons de commande et de livraison héritent du modèle d’état APJ :

```text
ClassMere
  -> ClassEtat
  -> ClassUser
  -> ClassMAPTable
```

Une insertion commence normalement dans un état de création.

```text
etat = 1
```

Une validation peut faire passer l’objet à l’état validé :

```java
bon.validerObject(referenceUtilisateur, connection);
```

Le mécanisme APJ appelle alors notamment :

```text
controlerUpdate
notification éventuelle
changement d’état
updateToTableWithHisto
```

La validation d’un parent maître/détail passe également par les lignes :

```text
parent.validerObject
  -> validation des filles
  -> validation du parent
```

## 23. Différence entre commande et livraison

| Élément | Bon de commande | Bon de livraison |
|---|---|---|
| Parent | `BonDeCommande` | `As_BondeLivraisonClient` |
| Enfant | `BonDeCommandeFille` | `As_BondeLivraisonClientFille` |
| Produit | produit commandé | produit livré |
| Quantité | quantité demandée | quantité effectivement livrée |
| État | création, validation | création, validation, livraison |
| Liaison | document initial | référence à la commande via `idbc` |
| Effet stock | généralement aucun mouvement immédiat | peut générer un mouvement de stock |
| Formulaire | `PageInsertMultiple` | `PageInsertMultiple` |
| Liste | `PageRecherche` | `PageRecherche` |

## 24. Mouvement de stock lors d’une livraison

Dans la classe réelle `As_BonDeLivraison`, la livraison peut créer un mouvement de stock :

```java
MvtStock mouvement = createMvtStock();
```

Puis les lignes de mouvement sont créées à partir des lignes livrées :

```java
for (As_BonDeLivraison_Fille ligne : lignes) {
    MvtStockFille stockLigne = new MvtStockFille();
    stockLigne.setIdProduit(ligne.getProduit());
    stockLigne.setEntree(ligne.getQuantite());
    stockLigne.setIdMvtStock(idMouvement);
}
```

Pour `ProduitSimple`, l’équivalent pédagogique est :

```java
MvtStock stock = new MvtStock();
stock.setIdMagasin(livraison.getMagasin());
stock.setDaty(livraison.getDaty());
stock.setIdTransfert(livraison.getId());

for (BonLivraisonSimpleLigne ligne : livraison.getFille()) {
    MvtStockFille detail = new MvtStockFille();
    detail.setIdProduit(ligne.getIdProduit());
    detail.setEntree(ligne.getQuantite());
    detail.setIdMvtStock(stock.getId());
}
```

Cette partie n’est pas fournie automatiquement par `ClassMere`. Elle relève d’une règle spécifique de la classe de livraison.

## 25. Flux complet illustré

### Création du bon de commande

```text
GET module.jsp?but=produit/bon-commande-simple-saisie.jsp
  -> PageInsertMultiple
  -> formulaire parent + lignes
  -> sélection de ProduitSimple

POST apresTarif.jsp
  -> BonCommandeSimple
  -> BonCommandeSimpleLigne[]
  -> controler
  -> construirePK parent
  -> insertion parent
  -> propagation idBc
  -> insertion lignes
  -> historique
```

### Création du bon de livraison

```text
GET module.jsp?but=produit/bon-livraison-simple-saisie.jsp&idBc=BCS000001
  -> chargement du bon de commande
  -> chargement des lignes
  -> calcul du reste à livrer
  -> PageInsertMultiple livraison

POST apresTarif.jsp
  -> BonLivraisonSimple
  -> BonLivraisonSimpleLigne[]
  -> validation des quantités
  -> construction de l’identifiant livraison
  -> insertion parent
  -> propagation idBl
  -> insertion lignes
  -> mise à jour éventuelle des quantités livrées
  -> mouvement de stock éventuel
  -> historique
```

## 26. Ce qui est APJ et ce qui est spécifique au projet

| Élément | Origine |
|---|---|
| `ClassMere` | framework APJ |
| `ClassFille` | framework APJ |
| `PageInsertMultiple` | framework APJ |
| propagation de l’identifiant parent | framework APJ |
| validation parent/enfants | framework APJ |
| `BonDeCommande` | code du projet construit sur APJ |
| `BonDeCommandeFille` | code du projet construit sur APJ |
| `As_BondeLivraisonClient` | code du projet construit sur APJ |
| calcul du reste à livrer | règle spécifique du projet |
| génération d’un mouvement de stock | règle spécifique du projet |
| liaison `idbc` | convention du projet |
| `ProduitSimple` | exemple du projet |
| `PageRecherche` | framework APJ |
| `PageInsertMultiple` | framework APJ |
| `MvtStock` | module applicatif lié au stock |

## 27. Règles à retenir

```text
1. Un bon est un parent ClassMere.
2. Une ligne est une ClassFille.
3. Le parent connaît la classe de ses filles.
4. La fille connaît le champ de liaison vers son parent.
5. PageInsertMultiple construit le formulaire maître/détail.
6. Les champs des lignes sont indexés avec _0, _1, _2...
7. APJ génère la clé du parent avant les clés des filles.
8. APJ propage l’identifiant parent aux filles.
9. La validation du parent peut valider les filles.
10. La relation commande/livraison et le stock sont des règles applicatives supplémentaires.
```

Le modèle mental est donc :

```text
ProduitSimple
  -> référence sélectionnable dans une ligne

BonCommandeSimple
  -> document qui demande des produits

BonLivraisonSimple
  -> document qui confirme les quantités livrées

ClassMere/ClassFille
  -> structure technique commune aux deux documents
```
