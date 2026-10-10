package ferme.acheminement;

import bean.CGenUtil;
import bean.ClassMere;
import ferme.configuration.MagasinElevage;

import java.sql.Connection;
import java.sql.Date;

public class ControlePoulet extends ClassMere {

    public static final String ANTECEDENT_BC = "BC";
    public static final String ANTECEDENT_BL = "BL";
    public static final String ANTECEDENT_CONTROLE = "CONTROLE";

    private String id;
    private Date daty;
    private String typeAntecedent;
    private String idAntecedent;
    private String idLigneAntecedent;
    private String idPoulet;
    private String idMagasin;
    private int quantiteTheorique;
    private int nbVivant;
    private int nbMort;
    private int nbPerdu;

    public ControlePoulet() throws Exception {
        this.setNomTable("CONTROLE_POULET");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CPL", "GETSEQCONTROLEPOULET");
        this.setId(this.makePK(c));
    }

    @Override
    public String getTuppleID() {
        return this.id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public void controler(Connection c) throws Exception {
        super.controler(c);
        this.controlerChamps();
        this.controlerAntecedent(c);
        this.controlerLieu(c);
        this.controlerCoherence();
        this.calculerNbPerdu();
    }

    @Override
    public void controlerUpdate(Connection c) throws Exception {
        super.controlerUpdate(c);
        this.controlerChamps();
        this.controlerAntecedent(c);
        this.controlerLieu(c);
        this.controlerCoherence();
        this.calculerNbPerdu();
    }

    private void controlerChamps() throws Exception {
        if (this.getDaty() == null) {
            throw new Exception("La date du contrôle est obligatoire");
        }
        if (this.getIdPoulet() == null || this.getIdPoulet().trim().isEmpty()) {
            throw new Exception("Le poulet contrôlé est obligatoire");
        }
        if (this.getTypeAntecedent() == null || this.getTypeAntecedent().trim().isEmpty()) {
            throw new Exception("Le type d'antécédent est obligatoire : " + ANTECEDENT_BC + ", " + ANTECEDENT_BL + " ou " + ANTECEDENT_CONTROLE);
        }
        if (this.getIdAntecedent() == null || this.getIdAntecedent().trim().isEmpty()) {
            throw new Exception("L'antécédent du contrôle est obligatoire");
        }
    }

    private void controlerAntecedent(Connection c) throws Exception {
        if (!ANTECEDENT_BC.equals(this.getTypeAntecedent())
                && !ANTECEDENT_BL.equals(this.getTypeAntecedent())
                && !ANTECEDENT_CONTROLE.equals(this.getTypeAntecedent())) {
            throw new Exception("Type d'antécédent non reconnu : " + this.getTypeAntecedent());
        }

        if (ANTECEDENT_CONTROLE.equals(this.getTypeAntecedent())) {
            ControlePoulet precedent = this.getAntecedentControle(c);
            if (precedent != null) {
                if (this.getDaty() != null && precedent.getDaty() != null && this.getDaty().before(precedent.getDaty())) {
                    throw new Exception("Le contrôle ne peut pas être antérieur au contrôle d'antécédent " + precedent.getTuppleID());
                }
                if (this.getIdPoulet() != null && !this.getIdPoulet().equals(precedent.getIdPoulet())) {
                    throw new Exception("Le contrôle ne peut pas concerner un poulet différent de celui du contrôle d'antécédent");
                }
            }
        }

        this.setQuantiteTheorique(this.calculerQuantiteTheoriqueDepuisAntecedent(c));
    }

    private void controlerLieu(Connection c) throws Exception {
        MagasinElevage lieu = this.getLieu(c);
        if (lieu == null) {
            throw new Exception("Le lieu du contrôle est introuvable");
        }
        if (lieu.getActif() == 0) {
            throw new Exception("Le lieu " + lieu.getNom() + " est inactif");
        }

        if (MagasinElevage.TYPE_LIEU_POULAILLER.equals(lieu.getTypeLieu())
                && !ANTECEDENT_CONTROLE.equals(this.getTypeAntecedent())) {
            throw new Exception("Un contrôle au poulailler attend un antécédent de type " + ANTECEDENT_CONTROLE
                    + " mais le type fourni est " + this.getTypeAntecedent());
        }
    }

    private void controlerCoherence() throws Exception {
        CalculAcheminement.controlerCoherenceControle(this.getQuantiteTheorique(), this.getNbVivant(), this.getNbMort());
        if (this.getQuantiteTheorique() > 0 && this.getNbVivant() + this.getNbMort() == 0) {
            throw new Exception("Un contrôle doit comporter au moins un vivant ou un mort");
        }
    }

    private void calculerNbPerdu() throws Exception {
        this.setNbPerdu(CalculAcheminement.calculerNbPerdu(this.getQuantiteTheorique(), this.getNbVivant(), this.getNbMort()));
    }

    public int calculerQuantiteTheoriqueDepuisAntecedent(Connection c) throws Exception {
        if (ANTECEDENT_CONTROLE.equals(this.getTypeAntecedent())) {
            ControlePoulet precedent = this.getAntecedentControle(c);
            if (precedent == null) {
                throw new Exception("Le contrôle d'antécédent " + this.getIdAntecedent() + " est introuvable");
            }
            return precedent.getNbVivant();
        }

        if (ANTECEDENT_BC.equals(this.getTypeAntecedent())) {
            return this.calculerQuantiteDepuisLigneBonCommande(c);
        }

        if (ANTECEDENT_BL.equals(this.getTypeAntecedent())) {
            return this.calculerQuantiteDepuisLigneLivraison(c);
        }

        throw new Exception("Type d'antécédent non reconnu : " + this.getTypeAntecedent());
    }

    private int calculerQuantiteDepuisLigneBonCommande(Connection c) throws Exception {
        if (this.getIdLigneAntecedent() == null || this.getIdLigneAntecedent().trim().isEmpty()) {
            throw new Exception("La ligne de bon de commande est obligatoire pour un antécédent de type " + ANTECEDENT_BC);
        }

        Integer quantiteSimple = this.calculerQuantiteDepuisBonCommandeSimple(c);
        if (quantiteSimple != null) {
            return quantiteSimple;
        }
        return this.calculerQuantiteDepuisAsBonDeCommande(c);
    }

    /**
     * Ligne du bon de commande « simple » : produit.BonCommandeSimpleLigne.
     * Renvoie null si cette table ne contient pas la ligne, ce qui laisse la
     * main au modèle des achats (As_BonDeCommande_Fille).
     */
    private Integer calculerQuantiteDepuisBonCommandeSimple(Connection c) throws Exception {
        produit.BonCommandeSimpleLigne critere = new produit.BonCommandeSimpleLigne();
        critere.setNomTable("BON_COMMANDE_SIMPLE_LIGNE");
        critere.setId(this.getIdLigneAntecedent());
        produit.BonCommandeSimpleLigne[] lignes = (produit.BonCommandeSimpleLigne[]) CGenUtil.rechercher(critere, null, null, c, "");
        if (lignes.length == 0) {
            return null;
        }
        produit.BonCommandeSimpleLigne ligne = lignes[0];
        if (!this.getIdAntecedent().equals(ligne.getIdBc())) {
            throw new Exception("La ligne " + this.getIdLigneAntecedent() + " n'appartient pas au bon de commande " + this.getIdAntecedent());
        }
        return (int) ligne.getQuantite();
    }

    /**
     * Ligne du bon de commande des achats : faturefournisseur.As_BonDeCommande_Fille.
     * C'est le modèle atteint depuis bondecommande-arbiochem-saisie.jsp, et donc
     * celui que la saisie manuelle produit réellement.
     */
    private int calculerQuantiteDepuisAsBonDeCommande(Connection c) throws Exception {
        faturefournisseur.As_BonDeCommande_Fille critere = new faturefournisseur.As_BonDeCommande_Fille();
        critere.setNomTable("AS_BONDECOMMANDE_FILLE");
        critere.setId(this.getIdLigneAntecedent());
        faturefournisseur.As_BonDeCommande_Fille[] lignes = (faturefournisseur.As_BonDeCommande_Fille[]) CGenUtil.rechercher(critere, null, null, c, "");
        if (lignes.length == 0) {
            throw new Exception("La ligne de bon de commande " + this.getIdLigneAntecedent() + " est introuvable");
        }
        faturefournisseur.As_BonDeCommande_Fille ligne = lignes[0];
        if (!this.getIdAntecedent().equals(ligne.getIdbc())) {
            throw new Exception("La ligne " + this.getIdLigneAntecedent() + " n'appartient pas au bon de commande " + this.getIdAntecedent());
        }
        return (int) ligne.getQuantite();
    }

    private int calculerQuantiteDepuisLigneLivraison(Connection c) throws Exception {
        if (this.getIdLigneAntecedent() == null || this.getIdLigneAntecedent().trim().isEmpty()) {
            throw new Exception("La ligne de bon de livraison est obligatoire pour un antécédent de type " + ANTECEDENT_BL);
        }
        faturefournisseur.As_BonDeLivraison_Fille critere = new faturefournisseur.As_BonDeLivraison_Fille();
        critere.setNomTable("AS_BONDELIVRAISON_FILLE");
        critere.setId(this.getIdLigneAntecedent());
        faturefournisseur.As_BonDeLivraison_Fille[] lignes = (faturefournisseur.As_BonDeLivraison_Fille[]) CGenUtil.rechercher(critere, null, null, c, "");
        if (lignes.length == 0) {
            throw new Exception("La ligne de bon de livraison " + this.getIdLigneAntecedent() + " est introuvable");
        }
        return (int) lignes[0].getQuantite();
    }

    public ControlePoulet getAntecedentControle(Connection c) throws Exception {
        ControlePoulet critere = new ControlePoulet();
        critere.setNomTable("CONTROLE_POULET");
        critere.setId(this.getIdAntecedent());
        ControlePoulet[] resultat = (ControlePoulet[]) CGenUtil.rechercher(critere, null, null, c, "");
        return resultat.length == 0 ? null : resultat[0];
    }

    public MagasinElevage getLieu(Connection c) throws Exception {
        if (this.getIdMagasin() == null || this.getIdMagasin().trim().isEmpty()) {
            return null;
        }
        MagasinElevage critere = new MagasinElevage();
        critere.setNomTable("MAGASIN_ELEVAGE");
        critere.setId(this.getIdMagasin());
        MagasinElevage[] resultat = (MagasinElevage[]) CGenUtil.rechercher(critere, null, null, c, "");
        return resultat.length == 0 ? null : resultat[0];
    }

    public boolean isControlePoulailler(Connection c) throws Exception {
        MagasinElevage lieu = this.getLieu(c);
        return lieu != null && MagasinElevage.TYPE_LIEU_POULAILLER.equals(lieu.getTypeLieu());
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public Date getDaty() {
        return daty;
    }

    public void setDaty(Date daty) {
        this.daty = daty;
    }

    public String getTypeAntecedent() {
        return typeAntecedent;
    }

    public void setTypeAntecedent(String typeAntecedent) {
        this.typeAntecedent = typeAntecedent;
    }

    public String getIdAntecedent() {
        return idAntecedent;
    }

    public void setIdAntecedent(String idAntecedent) {
        this.idAntecedent = idAntecedent;
    }

    public String getIdLigneAntecedent() {
        return idLigneAntecedent;
    }

    public void setIdLigneAntecedent(String idLigneAntecedent) {
        this.idLigneAntecedent = idLigneAntecedent;
    }

    public String getIdPoulet() {
        return idPoulet;
    }

    public void setIdPoulet(String idPoulet) {
        this.idPoulet = idPoulet;
    }

    public String getIdMagasin() {
        return idMagasin;
    }

    public void setIdMagasin(String idMagasin) {
        this.idMagasin = idMagasin;
    }

    public int getQuantiteTheorique() {
        return quantiteTheorique;
    }

    public void setQuantiteTheorique(int quantiteTheorique) {
        this.quantiteTheorique = quantiteTheorique;
    }

    public int getNbVivant() {
        return nbVivant;
    }

    public void setNbVivant(int nbVivant) {
        this.nbVivant = nbVivant;
    }

    public int getNbMort() {
        return nbMort;
    }

    public void setNbMort(int nbMort) {
        this.nbMort = nbMort;
    }

    public int getNbPerdu() {
        return nbPerdu;
    }

    public void setNbPerdu(int nbPerdu) {
        this.nbPerdu = nbPerdu;
    }
}