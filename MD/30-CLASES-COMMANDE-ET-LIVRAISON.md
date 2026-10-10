# Chaine achats : commande, livraison, facture

Le projet possede une chaine achats **complete et coherente**, mais qui n'a
rien a voir avec le domaine `ferme`. Ce document sert a le demontrer, pas a
proposer un pont.

## 1. Ce qui existe

### Fournisseur — paquet `faturefournisseur`

| Classe | Table | Cle |
| --- | --- | --- |
| `As_DemandeAchat` | `DEMANDEACHAT` | `DMC` |
| `As_ProformaAchat` | `PROFORMA_ACHAT` | — |
| `As_BonDeCommande` | `AS_BONDECOMMANDE` | `BC` |
| `As_BonDeCommande_Fille` | `AS_BONDECOMMANDE_FILLE` | `BCF` |
| `As_BonDeLivraison` | `AS_BONDELIVRAISON` | `BL` |
| `As_BonDeLivraison_Fille` | `AS_BONDELIVRAISON_FILLE` | `BLF` |
| `FactureFournisseur` | `FACTUREFOURNISSEUR` | — |

### Client / vente — paquet `vente`

| Classe | Table | Cle |
| --- | --- | --- |
| `BonDeCommande` | `BONDECOMMANDE_CLIENT` | `FCBC` |
| `BonDeCommandeFille` | `BONDECOMMANDE_CLIENT_FILLE` | — |
| `BonDeLivraisonClient` | `BONDELIVRAISON_CLIENT` | — |

`BonDeCommande` est le cas le plus riche du projet : `extends ClassMere
implements ClassIA`, avec quatre methodes de generation
(`genererLivraison`, `genererFacture`, `genererMiseEnCarton`) et des vues
metier dediees (`BONDECOMMANDE_CLIENTF_taux`, `BC_DETAILS_RESTE`,
`V_NUMEROBC_EN_COURS`).

## 2. La generation de livraison, cote fournisseur

`As_BonDeCommande.genererLivraison(String u, Connection c)` (ligne 466) est le
seul chainage metier complet du projet.

Fonctionnement :

1. Ouvre la commande et ses lignes dans la connexion `c`.
2. Cree un objet `As_BonDeLivraison` et reporte les donnees de la commande.
3. reporte ligne a ligne les quantites en `As_BonDeLivraison_Fille`.
4. **Fixe le lien de clobber `setClobberLigne(true)`** : une ligne de commande
   livrese ne peut plus etre modifiee.
5. Valide l'etat de la commande.

La connexion est **externe** : la methode ne fait ni `commit` ni `rollback`.
C'est l'appelant qui decide du sort de la transaction. C'est la raison pour
laquelle le module supporte un rollback propre, contrairement au reste du
domaine ferme ou les transactions sont implicites.

Meme principe pour `genererFacture(String u, Connection c)` (ligne 257) et
`genererLivraisonPourPrerempli` (ligne 391) qui pre-remplit la livraison depuis
la commande.

## 3. Le controle metier : devise unique

`As_BonDeCommande.controler(Connection c)` (ligne 223) :

```java
As_BonDeCommande_Fille[] bcfille = (As_BonDeCommande_Fille[]) CGenUtil.rechercher(
    new As_BonDeCommande_Fille(), null, null, c,
    "and idbc ='" + this.getId() + "' and idDevise!='" + this.getIdDevise() + "'");
if (bcfille.length > 0) {
    throw new Exception("Devise différent non accepté");
}
```

Une commande ne peut pas melanger deux devises. Controle unique, mais c'est un
controle reel et il est appele.

## 4. Le lien avec le lot est inexistant

Trois verifications negatives, chacune faite par recherche exhaustive :

1. **Aucun champ `idLot` dans la chaine achats.**
   `As_BonDeCommande_Fille` expose `id`, `produit`, `idproduit`, `idbc`,
   `quantite`, `pu`, `montant`, `tva`, `unite`, `idunite`, `remise`,
   `idDevise`, `tauxDeChange`, `montantTva`, `montantHT`, `montantTTC`,
   `produitLib`. Pas de lot, pas de race, pas de sexe, pas de qualite.
   Le reste du projet n'est decrit que par des **montants**.

2. **Aucune classe du depot n'instancie `ferme.lot.Lot` hors de `Lot`.**
   Un lot se cree donc a la main, depuis `lot-saisie.jsp`.

3. **Aucune vue ne joint les deux tables.**
   `v_qte_dispo_lot_sexe_qualite` ne mentionne ni `AS_BONDECOMMANDE` ni
   `AS_BONDELIVRAISON`. `AS_BONDELIVRAISON` ne mentionne ni `LOT` ni
   `receptionPoussinAeroport`.

La chaine achats est donc **completement orthogonale** a la chaine elevage.
Elle est financee, pas zootecnique.

## 5. Ce que cela implique pour le flux « commande → compartiment »

Le flux que vous decrivez — passer d'une commande a une mise en compartiment —
**n'est pas implemente dans ce projet**. Ce qui existe, c'est deux chemins
paralleles qui convergent uniquement au niveau du vocabulaire :

```
ACHATS                                  ELEVAGE
-------                                  --------
DemandeAchat
  └─> ProformaAchat
        └─> BonDeCommande (BC)
              ├─> genererLivraison ──> BonDeLivraison (BL)
              │                          └─> FactureFournisseur
              └─> genererFacture
                                        Lot  (creation manuelle)
                                          │
                                          ├─> ProgrammeZootechnique
                                          │
                                          └─> ReceptionPoussinAeroport
                                                │
                                                └─> TriageBatimentParquet
                                                      │ (idbatiment + idparquet
                                                      │  + idsexe + idqualite)
                                                      └─> SuiviJournalier
                                                            + Vaccination
                                                            + TransfertPoulet
                                                            + .. .
```

Le seul point de contact entre les deux colonnes est la table `LOT`, et elle
n'est **ecrite par aucun code du chemin de gauche**.

Pour obtenir le flux souhaite, il faudrait introduire une table de liaison
(`idbc` + `idlot`, ou une table de mouvement), et faire deriver les quantites
receptionnees de la quantite livree. Aucun de ces deux elements n'existe dans
le code d'origine.