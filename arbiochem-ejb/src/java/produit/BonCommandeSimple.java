package produit;

import bean.ClassMere;
import java.sql.Connection;

public class BonCommandeSimple extends ClassMere{
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
