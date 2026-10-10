package produit;

import bean.ClassFille;
import java.sql.Connection;

public class BonCommandeSimpleLigne extends ClassFille{
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
